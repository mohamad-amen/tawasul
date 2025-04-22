class Sizes {
  const Sizes._();
  static final double localVideoWidthWhenConnected = 125;
  static final double localVideoHeightWhenConnected = 200;
  static final double switchCameraButtonSizeWhenConnected = 40;
  static final double switchCameraButtonSizeWhenDisconnected = 70;
}

class Constants {
  const Constants._();
  static final Uri localUri = Uri(scheme: 'ws', host: '192.168.0.102', port: 8001);
  //replace with your local ip address

  static final Uri remoteUri = Uri(scheme: 'wss', host: 'tawasul-backend.onrender.com');
}
