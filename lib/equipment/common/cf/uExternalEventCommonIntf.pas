unit uExternalEventCommonIntf;

interface

type
  IExternalEventCommon = Interface
    procedure ExternalEvent(const Source, Event, Data: WideString);
  End;

implementation

end.
