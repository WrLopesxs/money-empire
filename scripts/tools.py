"""User-local tools. Uses Python standard library; no admin, pip or PATH changes."""
from __future__ import annotations

import argparse
import concurrent.futures
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import urllib.request
import zipfile
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parent.parent
TOOLS = ROOT / '.tools'
BUILD = ROOT / 'build' / 'MoneyEmpire.rbxlx'
PACKAGES = {
    'rojo': ('7.7.0', 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-windows-x86_64.zip'),
    'luau': ('0.738', 'https://github.com/luau-lang/luau/releases/download/0.738/luau-windows.zip'),
}
STUDIO_URLS = [
    'https://setup.rbxcdn.com/RobloxStudioInstaller.exe',
    'https://setup-aws.rbxcdn.com/RobloxStudioInstaller.exe',
]


def run(args, **kwargs):
    kwargs.setdefault('timeout', 45)
    return subprocess.run([str(a) for a in args], cwd=ROOT, check=True, **kwargs)


def download(url, destination):
    print(f'Baixando: {url}', flush=True)
    request = urllib.request.Request(url, headers={'User-Agent': 'MoneyEmpire-Setup'})
    with urllib.request.urlopen(request, timeout=25) as response:
        with destination.open('wb') as output:
            while chunk := response.read(1024 * 1024):
                output.write(chunk)


def studio_exe():
    versions = Path(os.environ['LOCALAPPDATA']) / 'Roblox' / 'Versions'
    candidates = list(versions.glob('*/RobloxStudioBeta.exe'))
    return max(candidates, key=lambda p: p.stat().st_mtime) if candidates else None


def setup(include_studio=False):
    TOOLS.mkdir(exist_ok=True)
    for name, (version, url) in PACKAGES.items():
        executable = TOOLS / name / f'{name}.exe'
        archive = TOOLS / f'{name}.zip'
        if not executable.exists():
            download(url, archive)
            with zipfile.ZipFile(archive) as package:
                target = (TOOLS / name).resolve()
                for member in package.namelist():
                    if not (target / member).resolve().is_relative_to(target):
                        raise RuntimeError('Caminho invalido no arquivo ZIP.')
                package.extractall(target)
        print(f'{name} {version}: {executable}', flush=True)
    manifest = {
        name: {'version': version, 'source': url, 'sha256': hashlib.sha256((TOOLS / f'{name}.zip').read_bytes()).hexdigest() if (TOOLS / f'{name}.zip').exists() else None}
        for name, (version, url) in PACKAGES.items()
    }
    (ROOT / 'docs' / 'installed-tools.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')
    if include_studio:
        if studio_exe():
            print(f'Roblox Studio ja instalado: {studio_exe()}')
            return
        installer = TOOLS / 'RobloxStudioInstaller.exe'
        for url in STUDIO_URLS:
            try:
                download(url, installer)
                break
            except Exception as error:
                print(f'Download indisponivel: {error}', flush=True)
        else:
            raise RuntimeError('Os servidores oficiais do Studio nao responderam. Ferramentas de teste ja instaladas. Tente novamente quando a conexao com Roblox estiver disponivel.')
        # Verify Windows Authenticode before executing the official installer.
        command = "$s = Get-AuthenticodeSignature -LiteralPath $env:MONEY_EMPIRE_INSTALLER; if ($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Roblox') { exit 1 }; $s.SignerCertificate.Subject"
        env = os.environ.copy()
        env['MONEY_EMPIRE_INSTALLER'] = str(installer)
        run(['powershell.exe', '-NoProfile', '-Command', command], env=env)
        startup = subprocess.STARTUPINFO()
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = 0
        print('Iniciando instalador oficial na conta atual, sem elevacao.', flush=True)
        process = subprocess.Popen([str(installer)], startupinfo=startup)
        try:
            result = process.wait(timeout=180)
            if result:
                raise RuntimeError(f'Instalador terminou com codigo {result}.')
        except subprocess.TimeoutExpired:
            print('Instalador ainda executando; confira se ha uma janela solicitando interacao.')
        if studio_exe():
            print(f'Studio instalado: {studio_exe()}')
        else:
            raise RuntimeError('Instalacao do Studio ainda nao confirmada. Consulte a janela/log do instalador.')


def build():
    BUILD.parent.mkdir(exist_ok=True)
    run([TOOLS / 'rojo' / 'rojo.exe', 'build', 'default.project.json', '-o', BUILD])
    tree = ET.parse(BUILD)
    scripts = {}
    for item in tree.iter('Item'):
        if item.attrib.get('class') in ('Script', 'LocalScript', 'ModuleScript'):
            properties = item.find('Properties')
            name = properties.find("string[@name='Name']").text
            source_node = properties.find("*[@name='Source']")
            source = source_node.text if source_node is not None else None
            if not source:
                raise RuntimeError(f'Script vazio no build: {name}')
            scripts[name] = item.attrib['class']
    assert scripts.get('Main') == 'Script'
    assert scripts.get('MoneyEmpireClient') == 'LocalScript'
    assert scripts.get('Economy') == 'ModuleScript'
    print(f'Build verificado: {len(scripts)} scripts completos em {BUILD}', flush=True)


def test(compile_sources=False):
    files = sorted((ROOT / 'src').rglob('*.luau')) + sorted((ROOT / 'tests').rglob('*.luau'))
    if compile_sources:
        for source in files:
            run([TOOLS / 'luau' / 'luau-compile.exe', '--null', source], stdout=subprocess.DEVNULL)
    result = run([TOOLS / 'luau' / 'luau.exe', 'tests/economy.spec.luau'], capture_output=True, text=True)
    print(result.stdout)
    build()
    report = {'time_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()), 'compiled_files': len(files) if compile_sources else 0, 'test_output': result.stdout, 'build': str(BUILD), 'studio_installed': str(studio_exe()) if studio_exe() else None, 'engine_playtest': 'not_run', 'cloud_datastore_test': 'not_run'}
    (ROOT / 'docs' / 'test-results.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print('Testes e build: OK. Testes do motor 3D e DataStore online sao separados.')


def diagnose():
    urls = STUDIO_URLS + ['https://clientsettingscdn.roblox.com/v2/client-version/WindowsStudio64', 'https://create.roblox.com']
    def check(url):
        try:
            with urllib.request.urlopen(url, timeout=15) as response:
                return {'url': url, 'status': response.status, 'length': response.headers.get('Content-Length')}
        except Exception as error:
            return {'url': url, 'error': str(error)}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        results = list(pool.map(check, urls))
    output = json.dumps(results, indent=2)
    print(output)
    (ROOT / 'docs' / 'network-diagnostics.json').write_text(output, encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('command', choices=['setup', 'build', 'test', 'open', 'diagnose'])
    parser.add_argument('--studio', action='store_true')
    parser.add_argument('--compile', action='store_true', help='Verificacao opcional de sintaxe com luau-compile; pode solicitar autorizacao no antivirus.')
    args = parser.parse_args()
    if args.command == 'setup': setup(args.studio)
    elif args.command == 'test': test(args.compile)
    elif args.command == 'build': build()
    elif args.command == 'diagnose': diagnose()
    elif args.command == 'open':
        build()
        studio = studio_exe()
        if not studio:
            raise RuntimeError('Studio nao instalado. Execute Instalar-ferramentas.cmd ou baixe em https://create.roblox.com/')
        # Interactive editor: visible so the user can sign in and press Play.
        subprocess.Popen([str(studio), str(BUILD)])


if __name__ == '__main__':
    try:
        main()
    except Exception as error:
        print(f'ERRO: {error}', file=sys.stderr)
        sys.exit(1)
