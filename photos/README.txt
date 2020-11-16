How to count google photos likes? <3

1] Start terminal in this folder. Type `ls` to ensure show there are scripts `write.sh`, `clean.sh`.

2] Run ./clean.sh in this folder to cleanup previous results. It's fine for it to fail when there are no previous results.

3] Run ./write.sh to start writing the results.

4] Go to the Google Photos, display likes from one photo (bottom-right), wait for them to load. Click into the likes (white space). Press CTRL+A and CTRL+C to copy all likes.

5] Paste into terminal waiting for the input and press CTRL+D to write one result. If the program exits, you probably tried to write results for one photo repeatedly. You can simply resume by [3].

6] After writing all photos, type CTRL+C to exit.

7] Run ./results.sh to get the results. You need to copy selection with CTRL+SHIFT+C instead of CTRL+C.
