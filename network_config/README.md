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
- **외부망** (enP1p1s0): `192.168.0.2`
- **카메라망** (enP8p1s0): `192.168.1.110`  
- **카메라 장치**: `192.168.1.168`

### IP 변경 방법
`network_config.json`에서 IP 주소만 수정 후 스크립트 재실행

### NetworkManager 비활성화
스크립트는 자동으로 NetworkManager를 비활성화하여 `/etc/network/interfaces`와의 충돌을 방지합니다.

## Troubleshooting

### 네트워크 설정 실패 시
```bash
# 기존 설정 복원
sudo cp /etc/network/interfaces.backup.* /etc/network/interfaces
sudo systemctl restart networking
sudo systemctl start NetworkManager
```

### 인터페이스 충돌 시
```bash
# 인터페이스 내리기
sudo ifdown enP1p1s0
sudo ifdown enP8p1s0

# 다시 설정 적용
sudo ./setup_network_json.sh --apply
```

### NetworkManager 재활성화 (필요시)
```bash
# NetworkManager 재활성화
sudo systemctl enable NetworkManager
sudo systemctl start NetworkManager

# networking 서비스 비활성화
sudo systemctl disable networking
```

## Files
- `network_config.json` - 설정 파일
- `setup_network_json.sh` - 설정 스크립트
- `README.md` - 이 파일 