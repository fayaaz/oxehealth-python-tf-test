# Oxehealth terraform python test : Fayaaz Ahmed

Terraform and source code for an AWS lambda function and all associated resources
to strip exif data from .jpg uploaded to bucket.

## Quick start

Install docker and docker-compose-v2
Create the .env file and add your credentials if needed
`touch .env`

Build the containers locally to get started
`docker compose build`

Run opentofu plan
`docker compose run --rm opentofu plan`

Run opentofu apply
`docker compose run --rm opentofu apply`


## Notes

- The method to strip EXIF data was taken from https://stackoverflow.com/questions/19786301/python-remove-exif-info-from-images
however this comment is correct:
```
WARNING: This will re-encode your JPG saving it with 75% quality. – 
user136036
Commented 2 days ago
```

- Doing this with PIL will reduce the size of the image (and probably quality). I would look at
 a different method (maybe using PIL/pillow or another library) as next steps to preserve the image quaity.

- I also had to use Python 3.12 as Python 3.13 and the pillow library did not work with lambda and layers. 

- Depending on the size of the images the 128MB of lambda memory may be insufficient to do the processing.
