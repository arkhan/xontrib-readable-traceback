import builtins
import os
import sys
import traceback

import pretty_traceback
import xonsh.tools
from xonsh.platform import os_environ
from xonsh.tools import display_error_message, to_logfile_opt


__all__ = ()
__version__ = '0.4.0'

$XONSH_SHOW_TRACEBACK = True
$XONSH_TRACEBACK_LOGFILE = None
$XONSH_READABLE_TRACEBACK = True

# Configuración de pretty-traceback
$PRETTY_TRACE_CONFIG = {
    'show_locals': True,      # Muestra variables locales en cada frame
    'truncate_locals': 100,   # Trunca valores locales a 100 caracteres
    'theme': 'monokai'        # Tema de colores (otros: 'default', 'colorful', etc.)
}

# Configurar pretty_traceback
def configure_pretty_traceback():
    if $XONSH_READABLE_TRACEBACK:
        config = $PRETTY_TRACE_CONFIG
        # Instalamos pretty_traceback con las opciones disponibles
        pretty_traceback.install(
            show_locals=config.get('show_locals', True),
            theme=config.get('theme', 'monokai'),
            truncate_locals=config.get('truncate_locals', 100)
        )
    else:
        # Desactivar pretty-traceback
        try:
            pretty_traceback.uninstall()
        except AttributeError:
            # En algunas versiones no existe uninstall, así que restauramos el excepthook original
            if hasattr(sys, '_original_excepthook'):
                sys.excepthook = sys._original_excepthook

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

    if $XONSH_READABLE_TRACEBACK:
        # Reconfigura pretty-traceback con la configuración actual
        configure_pretty_traceback()

        # Mostrar la excepción con pretty_traceback
        # (pretty_traceback ya interceptará las excepciones no capturadas a través de sys.excepthook,
        # pero aquí lo llamamos explícitamente para la excepción actual)
        sys.excepthook(tpe, v, tb)
    elif not $XONSH_SHOW_TRACEBACK:
        try:
            pretty_traceback.uninstall()
        except AttributeError:
            pass
        display_error_message()
    else:
        try:
            pretty_traceback.uninstall()
        except AttributeError:
            pass
        traceback.print_exc()

    if msg:
        msg = msg if msg.endswith('\n') else msg + '\n'
        sys.stderr.write(msg)

# Reemplazar la función de xonsh
xonsh.tools.print_exception = print_exception

# Configurar pretty-traceback al cargar el xontrib
configure_pretty_traceback()
