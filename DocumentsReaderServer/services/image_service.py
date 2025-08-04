from fastapi import UploadFile, HTTPException
from PIL import Image
from io import BytesIO

MAX_IMAGE_SIZE_MB = 1.999
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png"}

def resize_and_convert_image(photo: UploadFile) -> bytes:
    try:
        filename = photo.filename.lower()
        if not any(filename.endswith(ext) for ext in ALLOWED_EXTENSIONS):
            raise HTTPException(status_code=400, detail="Unsupported file type. Use JPG or PNG.")

        photo.file.seek(0)
        image = Image.open(photo.file)
        rgb_image = image.convert("RGB")

        quality = 95
        resize_factor = 0.9
        width, height = rgb_image.size

        while True:
            temp_image = rgb_image.resize((int(width), int(height)), Image.LANCZOS)

            buffer = BytesIO()
            temp_image.save(buffer, format="PNG", optimize=True)
            size_mb = buffer.tell() / (1024 * 1024)

            if size_mb <= MAX_IMAGE_SIZE_MB or (width < 200 or height < 200):
                break

            width *= resize_factor
            height *= resize_factor

        return buffer.getvalue()
    except Exception:
        raise HTTPException(status_code=400, detail="Invalid image format")
