module Adapter.RabbitMQ.EmailWorker where

import ClassyPrelude
import Control.Monad.Catch (MonadCatch)
import Katip
import Network.AMQP (Message)
import Network.Mail.Mime (Address (..), simpleMail')
import Network.Mail.SMTP (sendMail)

import qualified Adapter.RabbitMQ.Auth as MQAuth
import Adapter.RabbitMQ.Common
import qualified Domain.Auth as D

smtpPort :: Int
smtpPort = 1025

smtpHost :: String
smtpHost = "localhost:" ++ (show smtpPort)

senderAddress :: Address
senderAddress = Address (Just "HAuth") "no-reply@hauth.local"

consumeEmailVerification :: (KatipContext m, MonadCatch m, MonadUnliftIO m)
                         => (m Bool -> IO Bool) -> Message -> IO Bool
consumeEmailVerification runner msg =
  runner $ consumeAndProcess msg handler
  where
    handler payload =
      case D.mkEmail (MQAuth.emailVerificationPayloadEmail payload) of
        Left err -> withMsgAndErr msg err $ do
          $(logTM) ErrorS "Email format is invalid. Rejecting."
          return False
        Right email -> do
          liftIO $ sendEmail email (MQAuth.emailVerificationPayloadVerificationCode payload)
          $(logTM) InfoS "Verification email sent."
          return True

sendEmail :: D.Email -> D.VerificationCode -> IO ()
sendEmail email vCode = do
  let toAddress = Address Nothing (D.rawEmail email)
      verificationLink = "http://localhost:5173/auth/verifyEmail/" <> vCode
      subject = "Please verify your email"
      body = "Thanks for registering. Verify your account by visiting: " <> verificationLink
      mail = simpleMail' toAddress senderAddress subject (fromStrict body)
  sendMail smtpHost mail

init :: (KatipContext m, MonadCatch m, MonadUnliftIO m)
     => State -> (m Bool -> IO Bool) -> IO ()
init state runner = do
  initQueue state "verifyEmail" "auth" "userRegistered"
  initConsumer state "verifyEmail" (consumeEmailVerification runner)
