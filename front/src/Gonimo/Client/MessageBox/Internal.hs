{-# LANGUAGE RecursiveDo #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE RankNTypes #-}
module Gonimo.Client.MessageBox.Internal where

import Reflex.Dom
import Control.Monad
import Control.Monad.IO.Class (MonadIO, liftIO)
import Control.Lens
import Data.Monoid
import Data.Text (Text)
import Gonimo.Db.Entities (FamilyId, InvitationId)
import Gonimo.Types (Secret)
import qualified Gonimo.Db.Entities as Db
import qualified Gonimo.SocketAPI.Types as API
import qualified Gonimo.SocketAPI as API
import qualified GHCJS.DOM.Location as Location
import qualified GHCJS.DOM.History as History
import GHCJS.DOM.Types (ToJSVal, toJSVal, FromJSVal, fromJSVal, JSVal)
import qualified GHCJS.DOM.Window as Window
import qualified GHCJS.DOM as DOM
import Control.Monad.Trans.Maybe
import Data.Maybe (maybe)
import qualified Data.Aeson as Aeson
import qualified Data.Text.Encoding as T
import qualified Data.Text as T
import qualified Data.ByteString.Lazy as BL
import Network.HTTP.Types (urlDecode)
import Control.Monad.Fix (MonadFix)
import qualified Data.Aeson as Aeson
import Gonimo.SocketAPI.Types (InvitationReply)
import qualified Gonimo.Client.App.Types as App
import Gonimo.Client.Server (webSocket_recv)

invitationQueryParam :: Text
invitationQueryParam = "messageBox"

data Config t
  = Config { _configMessage :: Event t [ Message ]
           }

data MessageBox t
  = MessageBox { _action :: Event t [Action]
               }

data Message
  = ServerResponse API.ServerResponse

data Action
  = ServerRequest API.ServerRequest
  | SelectFamily !FamilyId

makeLenses ''Config
makeLenses ''MessageBox

fromApp :: Reflex t => App.Config t -> Config t
fromApp c = Config { _configMessage = (:[]) . ServerResponse <$> c^.App.server.webSocket_recv
                   }
