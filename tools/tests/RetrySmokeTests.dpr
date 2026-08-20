program RetrySmokeTests;

{ What the client does when a service says "slower".

  A DeepL run of 297 entries stopped twenty-nine seconds in:

    STOPPED: DeepL rejected the request (HTTP 429 Too Many Requests).

  Nothing was wrong with the key, the request or the language. The client had
  simply been changed to send one request per string instead of one per fifty,
  and then gave up after three attempts and waits of 300 and 600 milliseconds.
  Against a rate limit that is not waiting at all.

  A 429 is not a failure, it is an instruction. These check that it is obeyed:
  long enough, growing each time, and exactly as long as the service asks when
  it bothers to say. }

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  DAT.Provider.Retry in '..\..\source\provider\DAT.Provider.Retry.pas';

var
  Failures: Integer = 0;

procedure Check(const ACondition: Boolean; const AMessage: string);
begin
  if ACondition then
    Writeln('  ok    ', AMessage)
  else
  begin
    Writeln('  FAIL  ', AMessage);
    Inc(Failures);
  end;
end;

var
  Total: Integer;
  Attempt: Integer;
begin
  try
    Writeln;
    Writeln('=== which refusals are worth repeating ===');
    Check(TProviderRetry.IsWorthRetrying(429),
      'A rate limit is temporary and worth waiting out.');
    Check(TProviderRetry.IsWorthRetrying(500),
      'So is a server fault.');
    Check(TProviderRetry.IsWorthRetrying(503),
      'and a service unavailable.');
    Check(not TProviderRetry.IsWorthRetrying(400),
      'A malformed request will be malformed again just as fast.');
    Check(not TProviderRetry.IsWorthRetrying(403),
      'and a refused key will be refused again.');
    Check(not TProviderRetry.IsWorthRetrying(456),
      'and an exhausted quota will not refill while we wait.');

    Writeln;
    Writeln('=== the waits grow ===');
    Writeln(Format('  attempts 1..5: %d, %d, %d, %d, %d ms',
      [TProviderRetry.DelayMilliseconds(1, ''),
       TProviderRetry.DelayMilliseconds(2, ''),
       TProviderRetry.DelayMilliseconds(3, ''),
       TProviderRetry.DelayMilliseconds(4, ''),
       TProviderRetry.DelayMilliseconds(5, '')]));
    Check(TProviderRetry.DelayMilliseconds(1, '') >= 1000,
      'The first wait is a whole second, not a third of one.');
    Check(TProviderRetry.DelayMilliseconds(2, '') >
      TProviderRetry.DelayMilliseconds(1, ''),
      'and each wait is longer than the one before.');
    Check(TProviderRetry.DelayMilliseconds(3, '') >
      TProviderRetry.DelayMilliseconds(2, ''),
      'still.');
    Check(TProviderRetry.DelayMilliseconds(99, '') <= 30000,
      'No single wait runs away, however many attempts have failed.');

    Writeln;
    Writeln('=== being told exactly how long ===');
    Check(TProviderRetry.DelayMilliseconds(1, '5') = 5000,
      'Retry-After of 5 seconds is obeyed to the second.');
    Check(TProviderRetry.DelayMilliseconds(1, ' 12 ') = 12000,
      'even with spaces around it.');
    Check(TProviderRetry.DelayMilliseconds(1, '') = 1000,
      'and its absence falls back to the growing wait.');
    Check(TProviderRetry.DelayMilliseconds(2, 'Wed, 21 Oct 2026 07:28:00 GMT')
      = TProviderRetry.DelayMilliseconds(2, ''),
      'A date form nobody sends is treated as absent, not as a guess.');
    Check(TProviderRetry.DelayMilliseconds(1, '0') = 1000,
      'and so is a zero.');
    Check(TProviderRetry.DelayMilliseconds(1, '99999') <= 30000,
      'A service asking for a day is still capped.');

    Writeln;
    Writeln('=== enough attempts to outlast a rate limit ===');
    Check(TProviderRetry.MaximumAttempts >= 5,
      'More than the three that gave up after 900 milliseconds.');
    Total := 0;
    for Attempt := 1 to TProviderRetry.MaximumAttempts - 1 do
      Total := Total + TProviderRetry.DelayMilliseconds(Attempt, '');
    Writeln(Format('  total wait across all attempts: %.1f seconds',
      [Total / 1000]));
    Check(Total >= 15000,
      'Fifteen seconds or more of patience before a run is abandoned.');

    if Failures = 0 then
    begin
      Writeln('Retry smoke tests passed.');
      Halt(0);
    end;
    Writeln(Format('Retry smoke tests failed: %d', [Failures]));
    Halt(1);
  except
    on E: Exception do
    begin
      Writeln('EXCEPTION ', E.ClassName, ': ', E.Message);
      Halt(3);
    end;
  end;
end.
