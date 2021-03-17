# How to upload videos to youtube automagically

Folowing [this guide](https://developers.google.com/youtube/v3/guides/uploading_a_video).

## Steps

 0. You need access to youtube channel.

 1. Install python3-virtualenv python3-six python3-google-auth-httplib2

 2. Setup virtualenv.
   - `virtualenv run`
   - `run/bin/pip install --upgrade --force-reinstall oauth2client google-api-python-client httplib2 progressbar2`
   - `. run/bin/activate`

 3. We'll use the upload script:
   - Clone this git repo, and cd into it.
   - `git clone git@github.com:tokland/youtube-upload.git`

 4. You _need_ to create oauth2 credentials.
   - https://console.developers.google.com/apis/credentials
   - Insert them into json.
   - Allow access to Youtube API, to be available for your app ([f.e.](https://console.developers.google.com/apis/library/youtube.googleapis.com?project=devconfcz-269122)).

 5. Run the upload script directly first, with a sample file.
   - `youtube-upload/bin/youtube-upload --title=test file.mkv`
   - First time for the upload, you'll get a link - open it.
   - Authenticate through browser, and select devconf.cz.
   - The CODE you get, needs to be entered back into the `youtube-upload` script.

 6. On subsequent runs you should be authenticated, and can automatically upload videos.
   - See `run.rb`: a scirpt to extract metadata upload videos in 1 go.
   - Uses `done.txt` to keep track of already uploaded files (create it).
   - Check Youtube studio ([f.e.](https://studio.youtube.com/)).

 7. You may need a bigger quota.
   - Default is 30GBs per day (therefore use properly encoded videos).
   - Request to google needs a lot of time.
   - https://developers.google.com/youtube/v3/getting-started#quota
