TZ=UTC git show --quiet --date="format-local:%Y.%-m.%-d" --format="pipeline-%cd" >pipeline.txt
git hash-object --no-filters pipeline.txt
