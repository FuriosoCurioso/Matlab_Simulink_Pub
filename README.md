# MATLAB & Simulink Engineering Portfolio

**Sensor fusion, state estimation, embedded control and vehicle dynamics – from first measurement to verified model.**

![MATLAB](https://img.shields.io/badge/MATLAB-R2026b-orange?logo=mathworks) ![Simulink](https://img.shields.io/badge/Simulink-Stateflow-blue) ![Arduino](https://img.shields.io/badge/Hardware-Arduino%20UNO%20R4%20WiFi-00979D?logo=arduino) ![License](https://img.shields.io/badge/License-MIT-green)

This repository collects my engineering work from the Master's programme: Kalman-filter families for tracking and localisation, model-based design with Simulink and Stateflow on real hardware, measurement uncertainty and regression, and a verified model chain for vehicle longitudinal dynamics.

---

## Highlights

| Project | What it shows | Methods & tools |
|---|---|---|
| **[Vehicle longitudinal dynamics](Physik)** | Model chain from kinematics to a 3-DOF pitch/heave model; every stage verified (analytical solution, energy balance, limit case, reference block) | Simulink, Vehicle Dynamics Blockset, `ode45`, eigenvalue analysis, FFT |
| **[Multi-object tracking](MTS_SensorF/L07_08_Datenzuordnungsverfahren)** | Data association for several targets: distance matrix, confidence-based gating, track management | Kalman filter, confidence-based gating, assignment problem |
| **[Nonlinear state estimation](MTS_SensorF)** | EKF and UKF for robot pose and falling objects with air drag and wind; video-based ball tracking under heavy noise | Extended / Unscented Kalman filter, unscented transform |
| **[Odometry vs. Kalman localisation](MTS_SensorF/L15_Odometrie_Vs_Kalman)** | Drift of dead reckoning corrected by landmark measurements, with validation | Kalman filter, landmark-based localisation |
| **[AlphaBot robot on Arduino](A2_Odometrie)** | Closed-loop straight-line and circular driving on real hardware, gyro offset calibration online, tuning over WiFi | Simulink, Stateflow, P/PI control, XCP over WiFi, MPU-9250 |
| **[Sensor characterisation](A1_Messanalyse)** | IR and ultrasonic distance sensors: calibration curves and digital filtering | Simulink, Curve Fitting |
| **[Rocket belt apps](Rocket_Science_App)** | Interactive 1-DOF / 2-DOF analysis of the Bell Rocket Belt: thrust-to-weight ratio, propellant mass flow | MATLAB apps |

---

## Repository structure

```
├── A1_Messanalyse/       IR and ultrasonic sensor characterisation (Simulink)
├── A2_Odometrie/         AlphaBot odometry, gyro analysis, closed-loop driving (Simulink, Stateflow)
├── Arduino/              MATLAB ↔ Arduino: LEDs, debouncing, distance, temperature, pulse,
│                         barometric altitude, Bluetooth, small games
├── MTS_SensorF/          Multisensor fusion: coordinate transforms, 1D/2D Kalman, EKF, UKF,
│                         data association, multi-object tracking, video tracking
├── Physik/               Vehicle longitudinal dynamics: 1-DOF and 3-DOF Simulink models
├── Rocket_Science_App/   1-DOF / 2-DOF rocket and jet simulation apps
└── Sig_Sys/              Measurement uncertainty (GUM), regression, hypothesis tests, analogue signals
```

## Technical fields

- **State estimation:** linear, extended and unscented Kalman filters; process/measurement noise tuning; gating and data association
- **Model-based design:** Simulink, Stateflow, Vehicle Dynamics Blockset; deployment to Arduino UNO R4 WiFi with monitor-and-tune
- **Modelling & verification:** analytical reference solutions, energy balances, limit cases, eigenvalue/FFT comparison
- **Measurement engineering:** sensor calibration, filtering, uncertainty according to GUM, regression and hypothesis testing
- **MATLAB engineering:** structured, commented scripts with units; local functions; live plots and data logging from hardware

## Getting started

```bash
git clone https://github.com/FuriosoCurioso/Matlab_Simulink_Pub.git
```

1. Open MATLAB (developed with R2026b) and change into the project folder.
2. Run the script (`.m`) or open the model (`.slx`) and simulate.

**Requirements by area**

| Area | Needs |
|---|---|
| All | MATLAB |
| `A1`, `A2`, `Physik` | Simulink; `A2` also Stateflow and *Simulink Support Package for Arduino Hardware*; `Physik` also *Vehicle Dynamics Blockset* |
| `Arduino/` | *MATLAB Support Package for Arduino Hardware* and a connected board (adjust the COM port in the script) |
| `MTS_SensorF/`, `Sig_Sys/` | Some scripts use Statistics and Machine Learning, Signal Processing or Image Processing Toolbox |

> **Note:** Only source files (`.m`, `.slx`) are versioned. Measurement data (`.mat`), images and videos are not included, so scripts that load data need your own measurements. The `Physik` models expect parameter files (`parameterFahrzeug.m`, `parameterAufbau.m`) that are not part of this repository.

## Deutsch (Kurzfassung)

Portfolio aus Studium und Freizeit: Sensorfusion und Zustandsschätzung (Kalman, EKF, UKF, Multi-Objekt-Tracking), modellbasierte Entwicklung mit Simulink/Stateflow auf Arduino-Hardware, Messunsicherheit und Regression sowie eine verifizierte Modellkette zur Fahrzeug-Längsdynamik. Quelltexte; Messdaten liegen nicht bei und sind zu erzeugen; oder anfragen ;-) 

## License

[MIT](LICENSE) © 2026 Ramo
