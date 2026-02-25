{-# LANGUAGE ScopedTypeVariables #-}

module Adapter.HTTP.Web.Auth where

import ClassyPrelude
import Katip
import Text.Blaze.Html5 ((!))
import qualified Text.Blaze.Html5 as H
import qualified Text.Blaze.Html5.Attributes as A
-- import Text.Digestive.Scotty
import qualified Text.Digestive.Blaze.Html5 as DH
import qualified Text.Digestive.Form as DF
import qualified Text.Digestive.View as DF
import Text.Digestive.Form ((.:))
import Web.Scotty.Trans

import Adapter.HTTP.Common
import Adapter.HTTP.Web.Common
import Adapter.HTTP.Web.Utils (runForm)
import qualified Domain.Auth as D

-- * Routes

routes :: ( MonadIO m
          , MonadUnliftIO m
          , KatipContext m
          , D.AuthRepo m
          , D.EmailVerificationNotif m
          , D.SessionRepo m
          )
        => ScottyT m ()
routes = do
    -- home
    get "/" $
      redirect "/users"

    -- register
    get "/auth/register" $ do
      view <- DF.getForm "auth" authForm
      renderHtml $ registerPage view []

    post "/auth/register" $ do
      (view, mayAuth) <- runForm "auth" authForm
      case mayAuth of
        Nothing ->
          renderHtml $ registerPage view []
        Just auth -> do
          result <- lift $ D.register auth
          case result of
            Left D.RegistrationErrorEmailTaken ->
              renderHtml $ registerPage view ["Email has been taken"]
            Right _ -> do
              v <- DF.getForm "auth" authForm
              renderHtml $ registerPage v ["Registered successfully"]

    -- verify email
    get "/auth/verifyEmail/:code" $ do
      code <- pathParam "code" `catch` (\(_ :: SomeException) -> return "")
      result <- lift $ D.verifyEmail code
      case result of
        Left D.EmailVerificationErrorInvalidCode ->
          renderHtml $ verifyEmailPage "The verification code is invalid"
        Right _ ->
          renderHtml $ verifyEmailPage "Your Email has been verified"

    -- login
    get "/auth/login" $ do
      view <- DF.getForm "auth" authForm
      renderHtml $ loginPage view []

    post "/auth/login" $ do
      (view, mayAuth) <- runForm "auth" authForm
      case mayAuth of
        Nothing ->
          renderHtml $ loginPage view []
        Just auth -> do
          result <- lift $ D.login auth
          case result of
            Left D.LoginErrorEmailNotVerified ->
              renderHtml $ loginPage view ["Email has not been verified"]
            Left D.LoginErrorInvalidAuth ->
              renderHtml $ loginPage view ["Email/password is incorrect"]
            Right sId -> do
              setSessionIdInCookie sId
              redirect "/"

    -- get user
    get "/users" $ do
      userId <- reqCurrentUserId
      mayEmail <- lift $ D.getUser userId
      case mayEmail of
        Nothing ->
          throwString "Should not happen: email is not found"
        Just email ->
          renderHtml $ usersPage (D.rawEmail email)

usersPage :: Text -> H.Html
usersPage email =
  mainLayout "Users" $ do
    H.div $
      H.h1 "Users"
    H.div $
      H.toHtml email

verifyEmailPage :: Text -> H.Html
verifyEmailPage msg =
  mainLayout "Email Verification" $ do
    H.h1 "Email Verification"
    H.div $ H.toHtml msg
    H.div $ H.a ! A.href "/auth/login" $ "Login"

authForm :: Monad m => DF.Form [Text] m D.Auth
authForm =
  D.Auth <$> "email" .: emailForm
         <*> "password" .: passwordForm
  where
    emailForm = DF.validate (toResult . D.mkEmail) (DF.text Nothing)
    passwordForm = DF.validate (toResult. D.mkPassword) (DF.text Nothing)

authFormLayout :: DF.View [Text] -> Text -> Text -> [Text] -> H.Html
authFormLayout view formTitle action msgs =
  formLayout view action $ do
    H.h2 $
      H.toHtml formTitle
    H.div $
      errorList msgs
    H.div $ do
      H.label "Email"
      DH.inputText "email" view
      H.div $
        errorList' "email"
    H.div $ do
      H.label "Password"
      DH.inputPassword "password" view
      H.div $
        errorList' "password"
    H.input ! A.type_ "submit" ! A.value "Submit"
    where
      errorList' path =
        errorList . mconcat $ DF.errors path view
      errorList =
        H.ul . concatMap errorItem
      errorItem =
        H.li . H.toHtml

registerPage :: DF.View [Text] -> [Text] -> H.Html
registerPage view msgs =
  mainLayout "Register" $ do
    H.div $
      authFormLayout view "Register" "/auth/register" msgs
    H.div $
      H.a ! A.href "/auth/login" $ "Login"

loginPage :: DF.View [Text] -> [Text] -> H.Html
loginPage view msgs =
  mainLayout "Login" $ do
    H.div $
      authFormLayout view "Login" "/auth/login" msgs
    H.div $
      H.a ! A.href "/auth/register" $ "Register"
