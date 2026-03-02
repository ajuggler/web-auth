module Main where

import ClassyPrelude
import Control.Concurrent (threadDelay)
import Control.Monad.Catch (MonadCatch, MonadThrow)
import Control.Monad.Fail (MonadFail)
import Katip

import qualified Adapter.RabbitMQ.Common as MQ
import qualified Adapter.RabbitMQ.EmailWorker as EmailWorker

newtype App a = App
  { unApp :: ReaderT MQ.State (KatipContextT IO) a
  } deriving ( Applicative, Functor, Monad, MonadFail, MonadReader MQ.State, MonadIO
             , MonadThrow, MonadCatch, MonadUnliftIO, KatipContext, Katip )

run :: LogEnv -> MQ.State -> App a -> IO a
run le state = runKatipContextT le () mempty
             . flip runReaderT state
             . unApp

withKatip :: (LogEnv -> IO a) -> IO a
withKatip app =
  bracket createLogEnv closeScribes app
  where
    createLogEnv = do
      logEnv <- initLogEnv "HAuthEmailWorker" "prod"
      stdoutScribe <- mkHandleScribe ColorIfTerminal stdout (permitItem InfoS) V2
      registerScribe "stdout" stdoutScribe defaultScribeSettings logEnv

main :: IO ()
main =
  withKatip $ \le ->
    MQ.withState "amqp://guest:guest@localhost:5672/%2F" 16 $ \mqState -> do
      let runner = run le mqState
      EmailWorker.init mqState runner
      forever $ threadDelay 1000000
