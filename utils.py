#!/usr/bin/env python3

import psutil

temps = psutil.sensors_temperatures()


print(temps)