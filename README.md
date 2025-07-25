# AAS Camera Configuration

## ViewPro Configuration

### ViewPro Camera Settings
| Camera Model | ViewPro Stream URL | ViewPro Gimbal URL |
|-------------|-------------------|-------------------|
| **q10n** | `rtsp://192.168.1.168:554/main` | `rtsp://192.168.1.168:2000` |
| **Z10TIR** | `rtsp://192.168.2.119:554` | `rtsp://192.168.2.119:2000` |
| **A10T** | `rtsp://192.168.2.119:554` | `rtsp://192.168.2.119:2000` |
| **A40T** | `rtsp://192.168.2.119:554/live` | `rtsp://192.168.2.119:2000` |
| **U2** | `rtsp://192.168.2.119/554` | `rtsp://192.168.2.119:2000` |

### ViewPro Integration Notes
- ViewPro uses the same RTSP URLs as standard camera streams
- ViewPro gimbal control uses the same port (2000) as standard gimbal control
- ViewPro supports all camera models listed above
- ViewPro stream paths match the camera-specific paths (/main, /live, root)

## Network Configuration

### Network 1 (192.168.1.x)
- **q10n**: 192.168.1.168

### Network 2 (192.168.2.x)
- **Z10TIR, A10T, A40T, U2**: 192.168.2.119
