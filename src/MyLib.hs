module MyLib where

import ClassyPrelude
-- import Control.Exception.Safe (throw)
-- import Data.Aeson
-- import Data.Aeson.TH
-- import Language.Haskell.TH.Syntax (nameBase)
import Katip

someFunc :: IO ()
someFunc = putStrLn "someFunc"

----- :JSON: -----

{-
data User = User
  { userId :: Int
  , userName :: Text
  , userHobbies :: [Text]
  } deriving Show

-- instance ToJSON User where
--   toJSON (User uId name hobbies) = object [ "id" .= uId, "name" .= name, "hobbies" .= hobbies ]

-- instance FromJSON User where
--   parseJSON = withObject "User" $ \v ->
--     User <$> v .: "id"
--          <*> v .: "name"
--          <*> v .: "hobbies"

-- data User = User { userAge :: Int }
-- data Country = Country { countryAge :: Int }

-- $(deriveJSON defaultOptions ''User)

$(let structName = nameBase ''User
      lowercaseFirst (x:xs) = toLower [x] <> xs
      lowercaseFirst xs = xs
      options = defaultOptions { fieldLabelModifier = lowercaseFirst . drop (length structName) }
  in  deriveJSON options ''User
 )
-}


{-
data Test = TestNullary
          | TestUnary Int
          | TestProduct Int Text Double
          | TestRecord { recA :: Bool, recB :: Int }
$(deriveJSON defaultOptions ''Test)

----- :Exceptions: -----

data ServerException = ServerOnFireException
                     | ServerNotPluggedInException
                     deriving Show

instance Exception ServerException

data MyException = ThisException
                 | ThatException
                 deriving Show

instance Exception MyException

run :: IO () -> IO ()
run action = action
               `catch` (\e -> putStrLn $ "ServerException: " <> tshow (e :: ServerException))
               `catch` (\e -> putStrLn $ "MyException: " <> tshow (e :: MyException))
               `catchAny` (\e -> putStrLn $ tshow e)
-}

runKatip :: IO ()
runKatip = withKatip $ \le ->
  runKatipContextT le () mempty logSomething

withKatip :: (LogEnv -> IO a) -> IO a
withKatip app =
  bracket createLogEnv closeScribes app
  where
    createLogEnv = do
      logEnv <- initLogEnv "HAuth" "dev"
      stdoutScribe <- mkHandleScribe ColorIfTerminal stdout (permitItem InfoS) V2
      registerScribe "stdOut" stdoutScribe defaultScribeSettings logEnv

logSomething :: (KatipContext m) => m ()
logSomething = do
  $(logTM) InfoS "Log in no namespace"
  katipAddNamespace "ns1" $
    $(logTM) InfoS "Log in ns1"
  katipAddNamespace "ns2" $ do
    $(logTM) WarningS "Login ns2"
    katipAddNamespace "ns3" $
      katipAddContext (sl "userId" ("12" :: Text)) $ do
        $(logTM) InfoS "Log in ns2.ns3 with userId context"
        katipAddContext (sl "country" ("Singapoore" :: Text)) $
          $(logTM) InfoS "Log in ns2.ns3 with userId and country context"
