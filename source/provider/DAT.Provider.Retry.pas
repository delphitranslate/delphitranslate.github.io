unit DAT.Provider.Retry;

{ How long to wait before asking again.

  A 429 is not a failure. It is the service saying "slower", and the only wrong
  answer is to give up - which is what this used to do, after three attempts
  and waits of 300 and 600 milliseconds. Against a rate limit that is not
  waiting at all, and a run of nearly three hundred requests stopped
  twenty-nine seconds in with everything correct and nothing wrong except the
  pace.

  Two things matter. Wait long enough, growing the wait each time rather than
  hammering at a fixed interval; and honour Retry-After when the service
  troubles itself to say exactly how long, because a guess is never better than
  being told.

  The waits are computed here, separately from the sending, so they can be
  checked without a network or a clock. }

interface

type
  TProviderRetry = record
  public
    { Whether a status is worth trying again at all. A rate limit and a server
      fault are temporary; a bad request or a refused key will be refused
      again just as fast next time. }
    class function IsWorthRetrying(const AStatusCode: Integer): Boolean; static;
    { How long to wait before attempt number AAttempt, where the first attempt
      is 1. ARetryAfter is the header value as the service sent it, empty when
      it sent none. }
    class function DelayMilliseconds(const AAttempt: Integer;
      const ARetryAfter: string): Integer; static;
    { How many attempts are worth making. }
    class function MaximumAttempts: Integer; static;
  end;

implementation

uses
  System.SysUtils;

const
  { The first wait. A rate limit measured in requests per second needs about
    this long before there is any point asking again. }
  FirstDelayMilliseconds = 1000;
  { No single wait longer than this, however the arithmetic grows. }
  LongestDelayMilliseconds = 30000;
  { And no more waiting than this in total, so a service that is simply down
    does not hold a translation run open indefinitely. }
  AttemptCount = 6;

class function TProviderRetry.MaximumAttempts: Integer;
begin
  Result := AttemptCount;
end;

class function TProviderRetry.IsWorthRetrying(
  const AStatusCode: Integer): Boolean;
begin
  Result := (AStatusCode = 429) or (AStatusCode >= 500);
end;

class function TProviderRetry.DelayMilliseconds(const AAttempt: Integer;
  const ARetryAfter: string): Integer;
var
  Seconds: Integer;
  Step: Integer;
begin
  { Told exactly how long, wait exactly that long. The header is in seconds;
    a date form is also legal but no translation service sends one, and a
    value that will not parse is treated as absent rather than guessed at. }
  if TryStrToInt(Trim(ARetryAfter), Seconds) and (Seconds > 0) then
  begin
    Result := Seconds * 1000;
    if Result > LongestDelayMilliseconds then
      Result := LongestDelayMilliseconds;
    Exit;
  end;

  { Otherwise double the wait each time: one second, two, four, eight. }
  Step := AAttempt;
  if Step < 1 then
    Step := 1;
  if Step > 10 then
    Step := 10;
  Result := FirstDelayMilliseconds * (1 shl (Step - 1));
  if Result > LongestDelayMilliseconds then
    Result := LongestDelayMilliseconds;
end;

end.
