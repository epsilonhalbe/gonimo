{-# LANGUAGE CPP #-}
module Main where

import           Control.Concurrent.STM            (atomically)
import           Control.Concurrent.STM.TVar
import           Control.Monad.Logger
import qualified Data.ByteString.Char8             as S8
import qualified Data.Map.Strict                   as Map
import           Database.Persist.Sqlite
import           Network.Wai
import           Network.Wai.Handler.Warp
import           Network.Wai.Middleware.Static
import           Servant.Subscriber
import           System.IO                         (Handle, stderr)
import           System.Log.FastLogger             (fromLogStr)

import           Gonimo.Server
import           Gonimo.Server.Effects             (Config(..))
import           Gonimo.Server.Db.Entities
import           Gonimo.Server.InitDb
import           Database.Persist.Postgresql
import           Control.Monad.IO.Class         (MonadIO)

runGonimoLoggingT :: MonadIO m => LoggingT m a -> m a
runGonimoLoggingT = runStdoutLoggingT

devMain :: IO ()
devMain = do
  let subscriberPath = "subscriber"
  subscriber' <- atomically $ makeSubscriber subscriberPath runGonimoLoggingT
  pool        <- runGonimoLoggingT (createSqlitePool "testdb" 1)
  families    <- newTVarIO Map.empty
  flip runSqlPool pool $ do
    runMigration migrateAll
    initDb
  let config = Config {
    configPool = pool
  , configState      = families
  , configSubscriber = subscriber'
  }
  run 8081 $ addDevServer $ serveSubscriber subscriber' (getServer runGonimoLoggingT config)

prodMain :: IO ()
prodMain = do
  let subscriberPath = "subscriber"
  subscriber' <- atomically $ makeSubscriber subscriberPath runGonimoLoggingT
  -- empty connection string means settings are fetched from env.
  pool        <- runGonimoLoggingT (createPostgresqlPool "" 10)
  families    <- newTVarIO Map.empty
  flip runSqlPool pool $ do
    runMigration migrateAll
    initDb
  let config = Config {
    configPool = pool
  , configState      = families
  , configSubscriber = subscriber'
  }
  run 8081 $ serveSubscriber subscriber' (getServer runGonimoLoggingT config)

main :: IO ()
#ifdef DEVELOPMENT
main = devMain
#else
main = prodMain
#endif

addDevServer :: Application -> Application
addDevServer = staticPolicy $ addBase "../gonimo-front/dist" <|> addSlash
