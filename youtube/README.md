# How to upload videos to youtube automagically

Folowing [this guide](https://developers.google.com/youtube/v3/guides/uploading_a_video).

## Steps

 0. You need access to youtube channel.

 1. Install python-virtualenv python-six

 2. Setup virtualenv.
   - `virtualenv run
   - `run/bin/pip install --upgrade google-api-python-client`
   - `run/bin/pip install --upgrade oauth2client`

 3. Download (sample) upload script, credentials json.
   - also attached run.sh
 
 4. You _need_ to create oauth2 credentials.
   - https://console.developers.google.com/apis/credentials
   - Insert them into json.

 5. You can check it 'works' with a sample file (shouldn't be uploaded).
   - Authenticate through browser, select devconf.
   - Allow access to Youtube API to be available for your app ([f.e.](https://console.developers.google.com/apis/library/youtube.googleapis.com?project=devconfcz-269122)).

 6. On subsequent runs you should be authenticated, and actually upload videos.
   - Check Youtube studio ([f.e.](https://studio.youtube.com/channel/UCmYAQDZIQGm_kPvemBc_qwg)).
