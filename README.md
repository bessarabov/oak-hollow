# oak-hollow

There is 2 subsystems in this repo:

 * `api` — it can get and store info from huminidy/temperature IOT sensords
 * `frontend` — web application that show graphs with humidity/temperature. It is using [Cubism.js](https://github.com/square/cubism).

## How to run it

 1. You need a docker on your machine
 2. Run `./restart` in the working copy of this repo
 3. Send a sample metric:
```
curl -X POST -d '{"t": 24.30,"h": 60.80,"mac": "AA:BB:CC:00:11:22"}' http://127.0.0.1:3527/api/dot
```
 4. Open http://127.0.0.1:3527/ in your browser

Continue sending metrics with curl to see the data change (but instaed of `curl` it it intened that the IOT device is sending that data).

![Screenshot](https://upload.bessarabov.ru/bessarabov/wrsHNhlAe1-ats45-p63gUIN_jk.png)
