module Adapter.RabbitMQ.Common where

import ClassyPrelude
import Control.Concurrent.Lifted (fork)
import Control.Monad.Catch (MonadCatch)
import Data.Aeson
import Data.Has
import Katip
import Network.AMQP

data State = State
  { statePublisherChan :: Channel
  , stateConsumerChan :: Channel
  }

withState :: String -> Integer -> (State -> IO a) -> IO a
withState connUri prefetchCount action = bracket initState destroyState action'
  where
    initState = do
      publisher <- openConnAndChan
      consumer <- openConnAndChan
      return (publisher, consumer)

    openConnAndChan = do
      conn <- openConnection'' . either undefined id . fromURI $ connUri
      chan <- openChannel conn
      confirmSelect chan False
      qos chan 0 (fromInteger prefetchCount) True
      return (conn, chan)

    destroyState ((conn1, _), (conn2, _)) = do
      closeConnection conn1
      closeConnection conn2

    action' ((_, pubChan), (_, conChan)) = action (State pubChan conChan)

initExchange :: State -> Text -> IO ()
initExchange (State pubChan _) exchangeNm = do
  let exchange = newExchange { exchangeName = exchangeNm
                             , exchangeType = "topic"
                             }
  declareExchange pubChan exchange

initQueue :: State -> Text -> Text -> Text -> IO ()
initQueue state@(State pubChan _) queueNm exchangeNm routingKey = do
  initExchange state exchangeNm
  _ <- declareQueue pubChan (newQueue { queueName = queueNm })
  bindQueue pubChan queueNm exchangeNm routingKey

initConsumer :: State -> Text -> (Message -> IO Bool) -> IO ()
initConsumer (State _ conChan) queueNm handler = do
  void . consumeMsgs conChan queueNm Ack $ \(msg, env) -> void . fork $ do
    result <- handler msg
    if result then ackEnv env else rejectEnv env False

type Rabbit r m = (Has State r, MonadReader r m, MonadIO m)

publish :: (ToJSON a, Rabbit r m) => Text -> Text -> a -> m ()
publish exchange routingKey payload = do
  (State chan _) <- asks getter
  let msg = newMsg { msgBody = encode payload }
  liftIO . void $ publishMsg chan exchange routingKey msg

consumeAndProcess :: (KatipContext m, FromJSON a, MonadCatch m, MonadUnliftIO m)
                  => Message -> (a -> m Bool) -> m Bool
consumeAndProcess msg handler =
  case eitherDecode' (msgBody msg) of
    Left err -> withMsgAndErr msg err $ do
      $(logTM) ErrorS "Malformed payload. Rejecting."
      return False
    Right payload -> do
      result <- tryAny (handler payload)
      case result of
        Left err -> withMsgAndErr msg (displayException err) $ do
          $(logTM) ErrorS "There was an exception when processing the msg. Rejecting."
          return False
        Right bool' -> return bool'

withMsgAndErr :: (KatipContext m, ToJSON e) => Message -> e -> m a -> m a
withMsgAndErr msg err =
  katipAddContext (sl "mqMsg" (show msg) <> sl "error" err)
