{-# LANGUAGE ScopedTypeVariables #-}

module Adapter.HTTP.Common where

import ClassyPrelude
import Blaze.ByteString.Builder (toLazyByteString)
import Data.Aeson hiding (json)
import Data.Time.Lens
import Network.HTTP.Types.Status
import qualified Text.Digestive.Form as DF
import qualified Text.Digestive.Types as DF
import Web.Cookie
import Web.Scotty.Trans hiding (getCookie)

import qualified Domain.Auth as D

toResult :: Either e a -> DF.Result e a
toResult = either DF.Error DF.Success

setCookie :: MonadIO m => SetCookie -> ActionT m ()
setCookie =
  setHeader "Set-Cookie" . decodeUtf8 . toLazyByteString . renderSetCookie


getCookie :: MonadIO m => Text -> ActionT m (Maybe Text)
getCookie key = do
  mCookieStr <- header "Cookie"
  return $ do
    cookie <- parseCookies . encodeUtf8 . toStrict <$> mCookieStr
    let bsKey = encodeUtf8 key
    val <- lookup bsKey cookie
    return $ decodeUtf8 val

setSessionIdInCookie :: MonadIO m => D.SessionId -> ActionT m ()
setSessionIdInCookie sId = do
  curTime <- liftIO getCurrentTime
  setCookie $ def { setCookieName = "sId"
                  , setCookiePath = Just "/"
                  , setCookieValue = encodeUtf8 sId
                  , setCookieExpires = Just $ modL month (+ 1) curTime
                  , setCookieHttpOnly = True
                  , setCookieSecure = False
                  , setCookieSameSite = Just sameSiteLax
                  }

getCurrentUserId :: (MonadIO m, D.SessionRepo m) => ActionT m (Maybe D.UserId)
getCurrentUserId = do
  maySessionId <- getCookie "sId"
  case maySessionId of
    Nothing -> return Nothing
    Just sId -> lift $ D.resolveSessionId sId
