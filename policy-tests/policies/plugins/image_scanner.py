# plugins/image_scanner.py
#!/usr/bin/env python3

import sys
import json
import docker
from conftest import Plugin

class ImageScanner(Plugin):
    def __init__(self):
        super().__init__("image_scanner")
        self.client = docker.from_client()

    def scan_image(self, image_name):
        try:
            image = self.client.images.get(image_name)
            return self.analyze_layers(image)
        except docker.errors.ImageNotFound:
            return {"error": f"Image {image_name} not found"}

    def analyze_layers(self, image):
        history = image.history()
        return {
            "layers": len(history),
            "size": image.attrs['Size'],
            "created": image.attrs['Created'],
            "os": image.attrs['Os'],
            "architecture": image.attrs['Architecture']
        }

    def run(self, context):
        if context.input_type != "docker":
            return None

        results = []
        for image in context.files:
            scan_result = self.scan_image(image)
            results.append({
                "filename": image,
                "scan_result": scan_result
            })

        return results
