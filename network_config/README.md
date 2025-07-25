# Jetson Orin Network Configuration

## Quick Setup

### 1. 권한 설정
```bash
chmod +x setup_network_json.sh
```

### 2. 설정 확인
```bash
sudo ./setup_network_json.sh --config
```

### 3. 네트워크 설정 적용
```bash
sudo ./setup_network_json.sh --apply
```

## Configuration

### network_config.json
- **외부망** (enP1p1s0): `192.168.0.100`
- **카메라망** (enP8p1s0): `192.168.1.110`  
- **카메라 장치**: `192.168.1.168`

### IP 변경 방법
`network_config.json`에서 IP 주소만 수정 후 스크립트 재실행

## Files
- `network_config.json` - 설정 파일
- `setup_network_json.sh` - 설정 스크립트
- `README.md` - 이 파일 