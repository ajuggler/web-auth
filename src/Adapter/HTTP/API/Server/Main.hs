{-# LANGUAGE ScopedTypeVariables #-}

module Adapter.HTTP.API.Server.Main where

import ClassyPrelude
import Katip
import Network.HTTP.Types.Status
import Network.Wai
import Network.Wai.Middleware.Cors
import Network.Wai.Middleware.Gzip
import Web.Scotty.Trans

import qualified Adapter.HTTP.API.Server.Auth as Auth
import Adapter.HTTP.API.Server.Common
import qualified Domain.Auth as D

main :: ( MonadIO m
        , MonadUnliftIO m
        , KatipContext m
        , D.AuthRepo m
        , D.EmailVerificationNotif m
        , D.SessionRepo m
        )
     => (m Response -> IO Response) -> IO Application
main runner =
  cors (const $ Just policy) <$> scottyAppT defaultOptions runner routes
  where
    policy =
      simpleCorsResourcePolicy
        { corsOrigins = Just (["http://localhost:5173"], True)
        , corsMethods = ["GET","POST","PUT","PATCH","DELETE","OPTIONS"]
        , corsRequestHeaders = ["Content-Type","Authorization"]
        }

routes
  :: ( MonadIO m
     , MonadUnliftIO m
     , KatipContext m
     , D.AuthRepo m
     , D.EmailVerificationNotif m
     , D.SessionRepo m
     )
  => ScottyT m ()
routes = do
  middleware . gzip $ defaultGzipSettings { gzipFiles = GzipCompress }

  Auth.routes

  notFound $ do
    status status404
    json $ errorResponse ("NotFound" :: Text)

  defaultHandler $
    Handler $ \(e :: SomeException) -> do
      lift $ $(logTM) ErrorS $ "Unhandled error: " <> ls (displayException e)
      status status500
      json $ errorResponse ("InternalServiceError" :: Text)
