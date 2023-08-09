unit uTCPSyncConsts;

interface

const
  MAX_PACKET_SIZE = 8192;
  
resourcestring
  ERR_INVALID_SRV = 'Неверный адрес сервера или порт';
  ERR_NOT_CONNECTED = 'Соединение не установлено';
  ERR_NOT_RESPONSE = 'Сервер не отвечает';
  ERR_SEND_DATA = 'Ошибка отправки данных';
  ERR_WrongIPAddress = 'Неверный IP-адрес';
  ERR_CheckDataNotAssigned = 'Не задана функция проверки данных';
  ERR_RESPONSE_NOT_CORRECT = 'Некорректный или неполный ответ от сервера';

implementation

end.
