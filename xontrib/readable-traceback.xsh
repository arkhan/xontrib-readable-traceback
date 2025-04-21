import builtins
import os
import sys
import traceback

import xonsh.tools
from xonsh.platform import os_environ
from xonsh.tools import display_error_message, to_logfile_opt


__all__ = ()
__version__ = '0.4.0'

$XONSH_SHOW_TRACEBACK = True
$XONSH_TRACEBACK_LOGFILE = None
$XONSH_READABLE_TRACEBACK = True

# Importamos el módulo pero no llamamos a sus funciones directamente
try:
    import pretty_traceback
    PRETTY_TRACEBACK_AVAILABLE = True
except ImportError:
    PRETTY_TRACEBACK_AVAILABLE = False

# Guardamos el excepthook original al inicio
ORIGINAL_EXCEPTHOOK = sys.excepthook

def enable_pretty_traceback():
    """Activa pretty_traceback si está disponible"""
    if PRETTY_TRACEBACK_AVAILABLE and $XONSH_READABLE_TRACEBACK:
        # Simplemente importar pretty_traceback ya lo activa en algunas versiones
        # Si no, podemos intentar activarlo explícitamente
        try:
            pretty_traceback.install()
        except Exception:
            # Si falla, no hacemos nada (el módulo probablemente ya se activó al importarlo)
            pass
        return True
    return False

def disable_pretty_traceback():
    """Desactiva pretty_traceback y restaura el excepthook original"""
    if PRETTY_TRACEBACK_AVAILABLE:
        sys.excepthook = ORIGINAL_EXCEPTHOOK

def print_exception(msg=None, exc_info=None):
    """
    Override xonsh.tools.print_exception.
    """
    # log_file
    env = __xonsh__.env
    if env is None:
        manually_set_logfile = 'XONSH_TRACEBACK_LOGFILE' in env
    else:
        manually_set_logfile = env.is_manually_set('XONSH_TRACEBACK_LOGFILE')

    if not manually_set_logfile:
        log_msg = 'xonsh: To log full traceback to a file set: $XONSH_TRACEBACK_LOGFILE = <filename>\n'
        sys.stderr.buffer.write(log_msg.encode(encoding="utf-8"))

    log_file = env.get('XONSH_TRACEBACK_LOGFILE', None)
    log_file = to_logfile_opt(log_file)
    if log_file:
        with open(log_file, 'a') as f:
            traceback.print_exc(file=f)

    # Gestionar el traceback
    tpe, v, tb = sys.exc_info() if exc_info is None else exc_info

    if $XONSH_READABLE_TRACEBACK and PRETTY_TRACEBACK_AVAILABLE:
        # Activar pretty_traceback
        enable_pretty_traceback()
        # Llamar al handler actual de excepciones
        sys.excepthook(tpe, v, tb)
    elif not $XONSH_SHOW_TRACEBACK:
        # Desactivar pretty_traceback y mostrar mensaje simple
        disable_pretty_traceback()
        display_error_message()
    else:
        # Desactivar pretty_traceback y mostrar traceback normal
        disable_pretty_traceback()
        traceback.print_exc()

    if msg:
        msg = msg if msg.endswith('\n') else msg + '\n'
        sys.stderr.write(msg)

# Reemplazar la función de xonsh
xonsh.tools.print_exception = print_exception

# Configurar pretty-traceback al cargar el xontrib
if $XONSH_READABLE_TRACEBACK:
    enable_pretty_traceback()
