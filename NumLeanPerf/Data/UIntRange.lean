namespace NumLeanPerf

@[unbox]
structure USizeRange where
  start : USize
  stop : USize

@[unbox]
structure UInt8Range where
  start : UInt8
  stop : UInt8

@[unbox]
structure UInt16Range where
  start : UInt16
  stop : UInt16

@[unbox]
structure UInt32Range where
  start : UInt32
  stop : UInt32

@[unbox]
structure UInt64Range where
  start : UInt64
  stop : UInt64

instance : Membership USize USizeRange where
  mem _ _ := True

instance : Membership UInt8 UInt8Range where
  mem _ _ := True

instance : Membership UInt16 UInt16Range where
  mem _ _ := True

instance : Membership UInt32 UInt32Range where
  mem _ _ := True

instance : Membership UInt64 UInt64Range where
  mem _ _ := True

@[inline, specialize] def uSizeRange (start stop : USize) : USizeRange :=
  { start, stop }

@[inline, specialize] def uint8Range (start stop : UInt8) : UInt8Range :=
  { start, stop }

@[inline, specialize] def uint16Range (start stop : UInt16) : UInt16Range :=
  { start, stop }

@[inline, specialize] def uint32Range (start stop : UInt32) : UInt32Range :=
  { start, stop }

@[inline, specialize] def uint64Range (start stop : UInt64) : UInt64Range :=
  { start, stop }

@[inline] protected partial def USizeRange.forIn' [Monad m] (range : USizeRange) (init : β)
    (f : (i : USize) → i ∈ range → β → m (ForInStep β)) : m β :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (b : β) (i : USize) : m β := do
    if i < stop then
      match ← f i trivial b with
      | .yield b => loop b (i + 1)
      | .done b => pure b
    else
      pure b
  loop init start

@[inline] protected partial def UInt8Range.forIn' [Monad m] (range : UInt8Range) (init : β)
    (f : (i : UInt8) → i ∈ range → β → m (ForInStep β)) : m β :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (b : β) (i : UInt8) : m β := do
    if i < stop then
      match ← f i trivial b with
      | .yield b => loop b (i + 1)
      | .done b => pure b
    else
      pure b
  loop init start

@[inline] protected partial def UInt16Range.forIn' [Monad m] (range : UInt16Range) (init : β)
    (f : (i : UInt16) → i ∈ range → β → m (ForInStep β)) : m β :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (b : β) (i : UInt16) : m β := do
    if i < stop then
      match ← f i trivial b with
      | .yield b => loop b (i + 1)
      | .done b => pure b
    else
      pure b
  loop init start

@[inline] protected partial def UInt32Range.forIn' [Monad m] (range : UInt32Range) (init : β)
    (f : (i : UInt32) → i ∈ range → β → m (ForInStep β)) : m β :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (b : β) (i : UInt32) : m β := do
    if i < stop then
      match ← f i trivial b with
      | .yield b => loop b (i + 1)
      | .done b => pure b
    else
      pure b
  loop init start

@[inline] protected partial def UInt64Range.forIn' [Monad m] (range : UInt64Range) (init : β)
    (f : (i : UInt64) → i ∈ range → β → m (ForInStep β)) : m β :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (b : β) (i : UInt64) : m β := do
    if i < stop then
      match ← f i trivial b with
      | .yield b => loop b (i + 1)
      | .done b => pure b
    else
      pure b
  loop init start

@[inline] instance [Monad m] : ForIn' m USizeRange USize inferInstance where
  forIn' := USizeRange.forIn'

@[inline] instance [Monad m] : ForIn' m UInt8Range UInt8 inferInstance where
  forIn' := UInt8Range.forIn'

@[inline] instance [Monad m] : ForIn' m UInt16Range UInt16 inferInstance where
  forIn' := UInt16Range.forIn'

@[inline] instance [Monad m] : ForIn' m UInt32Range UInt32 inferInstance where
  forIn' := UInt32Range.forIn'

@[inline] instance [Monad m] : ForIn' m UInt64Range UInt64 inferInstance where
  forIn' := UInt64Range.forIn'

@[inline] protected partial def USizeRange.forM [Monad m] (range : USizeRange) (f : USize → m PUnit) : m PUnit :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (i : USize) : m PUnit := do
    if i < stop then
      f i
      loop (i + 1)
    else
      pure ⟨⟩
  loop start

@[inline] protected partial def UInt8Range.forM [Monad m] (range : UInt8Range) (f : UInt8 → m PUnit) : m PUnit :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (i : UInt8) : m PUnit := do
    if i < stop then
      f i
      loop (i + 1)
    else
      pure ⟨⟩
  loop start

@[inline] protected partial def UInt16Range.forM [Monad m] (range : UInt16Range) (f : UInt16 → m PUnit) : m PUnit :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (i : UInt16) : m PUnit := do
    if i < stop then
      f i
      loop (i + 1)
    else
      pure ⟨⟩
  loop start

@[inline] protected partial def UInt32Range.forM [Monad m] (range : UInt32Range) (f : UInt32 → m PUnit) : m PUnit :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (i : UInt32) : m PUnit := do
    if i < stop then
      f i
      loop (i + 1)
    else
      pure ⟨⟩
  loop start

@[inline] protected partial def UInt64Range.forM [Monad m] (range : UInt64Range) (f : UInt64 → m PUnit) : m PUnit :=
  let stop := range.stop
  let start := range.start
  let rec @[specialize] loop (i : UInt64) : m PUnit := do
    if i < stop then
      f i
      loop (i + 1)
    else
      pure ⟨⟩
  loop start

end NumLeanPerf
