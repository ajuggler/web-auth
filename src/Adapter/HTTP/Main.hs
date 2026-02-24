{-# LANGUAGE ScopedTypeVariables #-}

module Adapter.HTTP.Main where

import ClassyPrelude hiding (delete)
import Network.HTTP.Types.Status
import Web.Scotty.Trans

main :: IO ()
main = scottyT 3000 id routes

{-
routes :: (MonadIO m, MonadUnliftIO m) => ScottyT m ()
-- routes :: (MonadIO m) => ScottyT LText m ()
routes = get "/hello" $ text "Hello!"
-}

{-
routes :: (MonadIO m, MonadUnliftIO m) => ScottyT m ()
routes = do
  get "/" $ text "home"

  get "/hello/:name" $ do
    name <- pathParam "name"
    text $ "Hello, " <> name

  post "/users" $ text "adding user"

  put "/users/:id" $ text "updating user"

  patch "/users/:id" $ text "partially updating users"

  delete "/users/:id" $ text "deleting user"

  matchAny "/admin" $ text "I don't care about your HTTP verb"

  options (regex ".*") $ text "CORS usually use this"

  notFound $ text "404"
-}

{-
routes :: (MonadIO m, MonadUnliftIO m) => ScottyT m ()
routes = do
  get "/users/:userId/books/:bookId" $ do
    userId <- pathParam "userId"
    bookId <- pathParam "bookId"
    text $ userId <> " - " <> bookId

  get (regex "^/users/(.+)/investments/(.+)$") $ do
    fullPath <- pathParam "0"
    userId <- pathParam "1"
    investmentId <- pathParam "2"
    text $ fullPath <> " : " <> userId <> " - " <> investmentId
-}

{-
routes :: (MonadIO m, MonadUnliftIO m) => ScottyT m ()
routes = get "/add/:p1/:p2" $ do
  p1 <- pathParam "p1"
  p2 <- pathParam "p2"
  let sum = p1 + p2 :: Int
  text "Finish adding!"
-}

{-
routes :: (MonadIO m, MonadUnliftIO m) => ScottyT m ()
routes = get "/users" $ do
  when False $ throwString "bad request"
  text "just kidding!"
-}

{-
routes :: (MonadIO m, MonadUnliftIO m) => ScottyT m ()
routes =
  get "/hello" $ do
    mName <- queryParamMaybe "name"  -- reads ?name=John
    let name = fromMaybe ("anonymous" :: LText) mName
    text $ "Hello, " <> name
-}

routes :: (MonadIO m, MonadUnliftIO m) => ScottyT m ()
routes =
  get "/hello" $ do
    status unauthorized401
    addHeader "serverName" "Torre Blanca"
    text "you shall not pass!"
