defmodule Membrane.Element.Action do
  @moduledoc """
  This module contains type specifications of actions that can be returned
  from element callbacks.

  Returning actions is a way of element interaction with
  other elements and parts of framework. Each action may be returned by any
  callback (except for `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_init`
  and `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_terminate`, as they
  do not return any actions) unless explicitly stated otherwise.
  """

  alias Membrane.{Buffer, Caps, Event, Notification}
  alias Membrane.Element.Pad

  @typedoc """
  Sends a message to the watcher.
  """
  @type notify_t :: {:notify, Notification.t()}

  @typedoc """
  Sends an event through a pad (input or output).

  Forbidden when playback state is stopped.
  """
  @type event_t :: {:event, {Pad.ref_t(), Event.t()}}

  @typedoc """
  Allows to split callback execution into multiple applications of another callback
  (called from now sub-callback).

  Executions are synchronous in the element process, and each of them passes
  subsequent arguments from the args_list, along with the element state (passed
  as the last argument each time).

  Return value of each execution of sub-callback can be any valid return value
  of the original callback (this also means sub-callback can return any action
  valid for the original callback, unless expliciltly stated). Returned actions
  are executed immediately (they are NOT accumulated and executed after all
  sub-callback executions are finished).

  Useful when a long action is to be undertaken, and partial results need to
  be returned before entire process finishes (e.g. default implementation of
  `c:Membrane.Element.Base.Filter.handle_process_list/4` uses split action to invoke
  `c:Membrane.Element.Base.Filter.handle_process/4` with each buffer)
  """
  @type split_t :: {:split, {callback_name :: atom, args_list :: [[any]]}}

  @typedoc """
  Sends caps through a pad (it must be output pad). Sended caps must fit
  constraints on the pad.

  Forbidden when playback state is stopped.
  """
  @type caps_t :: {:caps, {Pad.ref_t(), Caps.t()}}

  @typedoc """
  Sends buffers through a pad (it must be output pad).

  Allowed only when playback state is playing.
  """
  @type buffer_t :: {:buffer, {Pad.ref_t(), Buffer.t() | [Buffer.t()]}}

  @typedoc """
  Makes a demand on a pad (it must be input pad in pull mode). It does NOT
  entail _sending_ demand through the pad, but just _requesting_ some amount
  of data from `Membrane.Core.PullBuffer`, which _sends_ demands automatically when it
  runs out of data.
  If there is any data available at the pad, the data is passed to
  `c:Membrane.Element.Base.Filter.handle_process_list/4`
  or `c:Membrane.Element.Base.Sink.handle_write_list/4` callback. Invoked callback is
  guaranteed not to receive more data than demanded.

  Demand size can be either a non-negative integer, that overrides existing demand,
  or a function that is passed current demand, and is to return the new demand.

  Allowed only when playback state is playing.
  """
  @type demand_t :: {:demand, {Pad.ref_t(), demand_size_t}}
  @type demand_size_t :: pos_integer | (pos_integer() -> non_neg_integer())

  @typedoc """
  Executes `c:Membrane.Element.Base.Mixin.SourceBehaviour.handle_demand/5` callback with
  given pad (which must be a output pad in pull mode) if this demand is greater
  than 0.

  Useful when demand could not have been supplied when previous call to
  `c:Membrane.Element.Base.Mixin.SourceBehaviour.handle_demand/5` happened, but some
  element-specific circumstances changed and it might be possible to supply
  it (at least partially).

  Allowed only when playback state is playing.
  """
  @type redemand_t :: {:redemand, Pad.ref_t()}

  @typedoc """
  Sends buffers/caps/event to all output pads of element (or to input pads when
  event occurs on the output pad). Used by default implementations of
  `c:Membrane.Element.Base.Mixin.SinkBehaviour.handle_caps/4` and
  `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_event/4` callbacks in filter.

  Allowed only when _all_ below conditions are met:
  - element is filter,
  - callback is `c:Membrane.Element.Base.Filter.handle_process_list/4`,
  `c:Membrane.Element.Base.Mixin.SinkBehaviour.handle_caps/4`
  or `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_event/4`,
  - playback state is valid for sending buffer, caps or event action
  respectively.

  Keep in mind that `c:Membrane.Element.Base.Filter.handle_process_list/4` can only
  forward buffers, `c:Membrane.Element.Base.Mixin.SinkBehaviour.handle_caps/4` - caps
  and `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_event/4` - events.
  """
  @type forward_t :: {:forward, Buffer.t() | [Buffer.t()] | Caps.t() | Event.t()}

  @typedoc """
  Suspends/resumes change of playback state.

  - `playback_change: :suspend` may be returned only from
  `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_stopped_to_prepared/2`,
  `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_playing_to_prepared/2`,
  `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_prepared_to_playing/2` and
  `c:Membrane.Element.Base.Mixin.CommonBehaviour.handle_prepared_to_stopped/2` callbacks,
  and defers playback state change until `playback_change: :resume` is returned.
  - `playback_change: :resume` may be returned from any callback, only when
  playback state change is suspended, and causes it to finish.

  There is no straight limit how long playback change can take, but keep in mind
  that it may affect application quality if not done quick enough.
  """
  @type playback_change_t :: {:playback_change, :suspend | :resume}

  @typedoc """
  Type that defines a single action that may be returned from element callbacks.
  Depending on element type, callback, current playback state and other
  circumstances there may be different actions available.
  """
  @type t ::
          event_t
          | notify_t
          | split_t
          | caps_t
          | buffer_t
          | demand_t
          | redemand_t
          | forward_t
          | playback_change_t
end
