module Control.Monad.Loops.STM where

import Control.Concurrent
import Control.Concurrent.STM

import Control.Monad (forever) -- for the benefit of haddock
import Data.Maybe

-- |'Control.Monad.forever' and 'Control.Concurrent.STM.atomically' rolled
-- into one.
atomLoop :: STM a -> IO ()
atomLoop x = go
    where go = atomically x >> go

-- |'atomLoop' with a 'forkIO'
forkAtomLoop :: STM a -> IO ThreadId
forkAtomLoop = forkIO . atomLoop

-- |'Control.Concurrent.STM.retry' until the given condition is true of
-- the given value.  Then return the value that satisfied the condition.
waitFor :: (a -> Bool) -> STM a -> STM a
waitFor p events = do
        event <- events
        if p event
                then return event
                else retry

-- |'Control.Concurrent.STM.retry' until the given value is True.
waitForTrue :: STM Bool -> STM ()
waitForTrue p = waitFor id p >> return ()

-- |'Control.Concurrent.STM.retry' until the given value is 'Just' _, returning
-- the contained value.
waitForJust :: STM (Maybe a) -> STM a
waitForJust m = fmap fromJust (waitFor isJust m)

-- |'waitFor' a value satisfying a condition to come out of a
-- 'Control.Concurrent.STM.TChan', reading and discarding everything else.
-- Returns the winner.
waitForEvent :: (a -> Bool) -> TChan a -> STM a
waitForEvent p events = waitFor p (readTChan events)

-- |'waitForEvent' a value satisfying a condition to come out of a
-- 'Control.Concurrent.STM.TChan', reading and discarding (really) everything else.
-- Returns the winner.
waitForEvent' :: (a -> Bool) -> TChan a -> STM a
waitForEvent' p chan = checkEvent
    where
      checkEvent = do
        event <- readTChan chan
        if p event
            then return event
            else checkEvent
