# ViewPro Configuration Files

## Overview
This directory contains ViewPro camera and gimbal configuration files for the AAS (Autonomous Aerial System) project.

## Configuration Files

### q10n_cam_ip_config.json
- **Purpose**: Configuration file for q10n camera and gimbal settings
- **Usage**: Used by ViewPro services to connect to camera and gimbal hardware
- **Location**: `/home/{whoami}/imc_orin/viewpro/cam_ip_config.json` (active file)
- **IP Address**: 192.168.1.168 (camera and gimbal)

### File Structure
```json
{
    "camera": {
        "ip_address": "rtsp://192.168.1.168:554/main",
        "username": "",
        "password": "",
        "rtsp": {
            "transport": "tcp",
            "buffer_size": 2000000,
            "timeout": 5
        }
    },
    "gimbal": {
        "ip_address": "192.168.1.168",
        "connection_type": "tcp",
        "port": "2000",
        "pan_range": [-180, 180],
        "tilt_range": [-90, 90]
    },
    "stream_modes": {
        "normal": {
            "resolution": "1920x1080",
            "fps": 30,
            "bitrate": 4000000
        },
        "inference": {
            "resolution": "1280x720", 
            "fps": 15,
            "bitrate": 2000000
        },
        "tracking": {
            "resolution": "1920x1080",
            "fps": 25,
            "bitrate": 3000000
        }
    }
}
```

## Usage

### Camera Configuration
- **RTSP Stream**: `rtsp://192.168.1.168:554/main`
- **Transport**: TCP
- **Buffer Size**: 2MB
- **Timeout**: 5 seconds

### Gimbal Configuration
- **IP Address**: 192.168.1.168
- **Port**: 2000
- **Connection Type**: TCP
- **Pan Range**: -180° to +180°
- **Tilt Range**: -90° to +90°

### Stream Modes
1. **Normal Mode**: 1920x1080 @ 30fps (4Mbps)
2. **Inference Mode**: 1280x720 @ 15fps (2Mbps)
3. **Tracking Mode**: 1920x1080 @ 25fps (3Mbps)

## Integration Notes
- This configuration is used by the `imc-gimbal-main.service`
- The ViewPro SDK reads this configuration to establish connections
- Changes to this file require service restart: `sudo systemctl restart imc-gimbal-main.service`
- The active configuration file is located at `/home/nvidia/imc_orin/viewpro/cam_ip_config.json`

## Related Services
- `imc-gimbal-main.service`: Main gimbal control service
- `imc-viewpro-publisher.service`: ViewPro data publisher
- `imc-gimbal-subscriber.service`: Gimbal command subscriber