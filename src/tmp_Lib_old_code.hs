someFunc :: IO ()
someFunc = withKatip $ \le -> do
  mState <- newTVarIO M.initialState
  PG.withState pgCfg $ \pgState ->
    Redis.withState redisCfg $ \redisState ->
      -- run le (pgState, redisState, mState) action
      MQ.withState mqCfg 16 $ \mqState -> do
        let runner = run le (pgState, redisState, mqState, mState)
        MQAuth.init mqState runner
        runner action
  where
    mqCfg = "amqp://guest:guest@localhost:5672/%2F"
    redisCfg = "redis://localhost:6379/0"
    pgCfg = PG.Config
            { PG.configUrl = "postgresql://localhost/hauth"
            , PG.configStripeCount = 2
            , PG.configMaxOpenConnPerStripe = 5
            , PG.configIdleConnTimeout = 10
            }





action :: App ()
action = do
  let email = either undefined id $ mkEmail "eckyy@test.com"
      pswd = either undefined id $ mkPassword "1234ABCDefghh"
      auth = Auth email pswd
  register auth
  Just vCode <- M.getNotificationsForEmail email
  verifyEmail vCode
  Right session <- login auth
  Just uId <- resolveSessionId session
  Just registeredEmail <- getUser uId
  putStr "\n"
  print (session, uId, rawEmail registeredEmail)
  putStr "\n"
