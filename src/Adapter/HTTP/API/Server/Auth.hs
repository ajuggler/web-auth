module Adapter.HTTP.API.Server.Auth where

import ClassyPrelude
import Katip
import Network.HTTP.Types.Status
import Text.Digestive.Form ((.:))
import qualified Text.Digestive.Form as DF
import Web.Scotty.Trans

import Adapter.HTTP.API.Server.Common
import Adapter.HTTP.API.Types.Auth ()
import Adapter.HTTP.Common
import qualified Domain.Auth as D

routes :: (MonadIO m, MonadUnliftIO m, KatipContext m, D.AuthRepo m, D.EmailVerificationNotif m, D.SessionRepo m)
       => ScottyT m ()
routes = do
  -- register
  post "/api/auth/register" $ do
    input <- parseAndValidateJSON authForm
    domainResult <- lift $ D.register input
    case domainResult of
      Left err -> do
        status status400
        json err
      Right _ ->
        return ()

  -- verify email
  post "/api/auth/verifyEmail" $ do
    input <- parseAndValidateJSON verifyEmailForm
    domainResult <- lift $ D.verifyEmail input
    case domainResult of
      Left err -> do
        status status400
        json err
      Right _ ->
        return ()

  -- login
  post "/api/auth/login" $ do
    input <- parseAndValidateJSON authForm
    domainResult <- lift $ D.login input
    case domainResult of
      Left err -> do
        status status400
        json err
      Right sId -> do
        setSessionIdInCookie sId
        return ()

  -- get user
  get "/api/users" $ do
    userId <- reqCurrentUserId
    mayEmail <- lift $ D.getUser userId
    case mayEmail of
      Nothing ->
        throwString "Should not happen: SessionId map to invalid UserId"
      Just email ->
        json $ email

authForm :: Monad m => DF.Form [Text] m D.Auth
authForm =
  D.Auth <$> "email" .: emailForm
       <*> "password" .: passwordForm
  where
    emailForm = DF.validate (toResult . D.mkEmail) (DF.text Nothing)
    passwordForm = DF.validate (toResult . D.mkPassword) (DF.text Nothing)

verifyEmailForm :: Monad m => DF.Form [Text] m D.VerificationCode
verifyEmailForm = DF.text Nothing
