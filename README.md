# robusta-poc

```
gcloud container clusters get-credentials poc-cluster \
  --zone us-central1-a \
  --project tidal-fusion-372316

  gcloud compute ssh iap-proxy \
  --project tidal-fusion-372316 \
  --zone us-central1-a \
  --  -L 8888:localhost:8888 -N -q -f
```