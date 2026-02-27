module Adapter.HTTP.API.Client.Auth where

import ClassyPrelude
import Control.Exception (throw)
import Data.Has
import Data.Aeson
import Network.HTTP.Client
import Network.HTTP.Types

import Adapter.HTTP.API.Client.Common
import Adapter.HTTP.API.Types.Auth ()
import qualified Domain.Auth as D

register :: HttpClient r m => D.Auth -> m (Either D.RegistrationError ())
register auth = do
  State initReq mgr <- asks getter
  let req = initReq
        { method = "POST"
        , path = "/api/auth/register"
        , requestBody = RequestBodyLBS . encode $ auth
        }
  resp <- liftIO $ httpLbs req mgr
  case responseStatus resp of
    (Status 200 _) -> return $ Right ()
    _              -> Left <$> parseOrErr req resp

verifyEmail :: HttpClient r m
            => D.VerificationCode -> m (Either D.EmailVerificationError ())
verifyEmail code = do
  State initReq mgr <- asks getter
  let req = initReq
        { method = "POST"
        , path = "/api/auth/verifyEmail"
        , requestBody = RequestBodyLBS . encode $ code
        }
  resp <- liftIO $ httpLbs req mgr
  case responseStatus resp of
    (Status 200 _) -> return $ Right ()
    _              -> Left <$> parseOrErr req resp

login :: HttpClient r m => D.Auth -> m (Either D.LoginError Session)
login auth = do
  State initReq mgr <- asks getter
  let req = initReq
        { method = "POST"
        , path = "/api/auth/login"
        , requestBody = RequestBodyLBS $ encode auth
        }
  resp <- liftIO $ httpLbs req mgr
  case responseStatus resp of
    (Status 200 _) -> return $ Right $ responseCookieJar resp
    _              -> Left <$> parseOrErr req resp

getUser :: HttpClient r m => Session -> m D.Email
getUser session = do
  State initReq mgr <- asks getter
  let req = initReq
        { method = "GET"
        , path = "/api/users"
        , cookieJar = Just session
        }
  resp <- liftIO $ httpLbs req mgr
  case responseStatus resp of
    (Status 200 _) -> parseOrErr req resp
    _              -> throw $ UnexpectedResponse req resp

