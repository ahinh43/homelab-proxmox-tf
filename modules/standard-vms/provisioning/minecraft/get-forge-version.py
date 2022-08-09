
import requests
import fire


# Get the build number

def get_build_url(version):
  url = f'https://files.minecraftforge.net/net/minecraftforge/forge/index_{version}.html'
  a = requests.get(url)
  b = a.text

  start = b.find(f"https://maven.minecraftforge.net/net/minecraftforge/forge/{version}")
  end = b.find("-installer.jar")
  url = f"{b[start:end]}-installer.jar"
  return url

if __name__ == '__main__':
  fire.Fire(get_build_url)