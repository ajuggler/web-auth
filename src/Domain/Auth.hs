module Domain.Auth (
  -- * Types
  Auth(..),
  Email,
  mkEmail,
  rawEmail,
  Password,
  mkPassword,
  rawPassword,
  UserId,
  VerificationCode,
  SessionId,
  RegistrationError(..),
  EmailVerificationError(..),
  LoginError(..),

  -- * Ports
  AuthRepo(..),
  EmailVerificationNotif(..),
  SessionRepo(..),

  -- * Use cases
  register,
  verifyEmail,
  login,
  resolveSessionId,
  getUser
) where

import ClassyPrelude
import Control.Monad.Except
import Katip
import Text.Regex.PCRE.Heavy

import Domain.Validation

data Auth = Auth
  { authEmail :: Email
  , authPassword :: Password
  } deriving (Show, Eq)

newtype Email = Email { emailRaw :: Text } deriving (Show, Eq, Ord)

data RegistrationError = RegistrationErrorEmailTaken
  deriving (Show, Eq)

data EmailValidationErr = EmailValidationErrInvalidEmail

newtype PasswordValidationErr = PasswordValidationErr Text

data EmailVerificationError = EmailVerificationErrorInvalidCode
  deriving (Show, Eq)

class Monad m => AuthRepo m where
  addAuth :: Auth -> m (Either RegistrationError (UserId, VerificationCode))
  setEmailAsVerified :: VerificationCode -> m (Either EmailVerificationError (UserId, Email))
  findUserByAuth :: Auth -> m (Maybe (UserId, Bool))
  findEmailFromUserId :: UserId -> m (Maybe Email)

class Monad m => EmailVerificationNotif m where
  notifyEmailVerification :: Email -> VerificationCode -> m ()

class Monad m => SessionRepo m where
  newSession :: UserId -> m SessionId
  findUserIdBySessionId :: SessionId -> m (Maybe UserId)

----- :Validation: -----

rawEmail :: Email -> Text
rawEmail = emailRaw

mkEmail :: Text -> Either [Text] Email
mkEmail = validate Email
  [ regexMatches
    [re|^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}$|]
    "Not a valid email"
  ]

newtype Password = Password { passwordRaw :: Text } deriving (Show, Eq)

rawPassword :: Password -> Text
rawPassword = passwordRaw

mkPassword :: Text -> Either [Text] Password
mkPassword = validate Password
  [ lengthBetween 5 50 "Should be between 5 and 50"
  , regexMatches [re|\d|] "Should contain number"
  , regexMatches [re|[A-Z]|] "Should contain uppercase letter"
  , regexMatches [re|[a-z]|] "Should contain lowercase letter"
  ]

----- :Registration: -----

type VerificationCode = Text

withUserIdContext :: (KatipContext m) => UserId -> m a -> m a
withUserIdContext uId = katipAddContext $ sl "userId" uId

register :: (KatipContext m, AuthRepo m, EmailVerificationNotif m)
         => Auth -> m (Either RegistrationError ())
register auth = runExceptT $ do
  (uId, vCode) <- ExceptT $ addAuth auth
  let email = authEmail auth
  lift $ notifyEmailVerification email vCode
  withUserIdContext uId $
    $(logTM) InfoS $ ls (rawEmail email) <> " is registered successfully"

----- :Email Verification: -----

verifyEmail :: (KatipContext m, AuthRepo m)
            => VerificationCode -> m (Either EmailVerificationError ())
verifyEmail vCode = runExceptT $ do
  (uId, email) <- ExceptT $ setEmailAsVerified vCode
  withUserIdContext uId $
    $(logTM) InfoS $ ls (rawEmail email) <> " is verified successfuly"
  return ()

----- :Login and Resolving Session: -----

type UserId = Int

type SessionId = Text

data LoginError = LoginErrorInvalidAuth
                | LoginErrorEmailNotVerified
                deriving (Show, Eq)

login :: (KatipContext m, AuthRepo m, SessionRepo m)
      => Auth -> m (Either LoginError SessionId)
login auth = runExceptT $ do
  result <- lift $ findUserByAuth auth

  case result of
    Nothing -> throwError LoginErrorInvalidAuth
    Just (_, False) -> throwError LoginErrorEmailNotVerified
    Just (uId, _) -> withUserIdContext uId . lift $ do
      sId <- newSession uId
      $(logTM) InfoS $ ls (rawEmail $ authEmail auth) <> " logged in successfully"
      return sId

resolveSessionId :: SessionRepo m => SessionId -> m (Maybe UserId)
resolveSessionId = findUserIdBySessionId

----- :User Page: -----

getUser :: AuthRepo m => UserId -> m (Maybe Email)
getUser = findEmailFromUserId

