program EquipmentCommonCF;

uses
  Common.BaseSecurity,
  {$IF CompilerVersion > 21}
  Common.CommonTypes,
  Common.GetCOMPorts,
  Common.VideoCam2,
  DelphiZXIngQRCode,
  uUninstallActions,
  uWinSvcUtils,
  Web.Win.Sockets,
  {$IFEND}
  {$IFDEF OXML}
  OXmlSerializeCollection,
  uSArrayOXmlSerializer,
  {$ENDIF OXML}
  uBigInt,
  uCommManager,
  uCommonUtils,
  uDiffiHellmanAlgorithm,
  uEquipmentErrors,
  uPipes,
  uSimpleCrypt,
  uVInfo,
  uXMLUtils
  ;

begin
end.
