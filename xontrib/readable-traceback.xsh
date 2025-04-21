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
    'display_locals': True,      # Muestra variables locales en cada frame
    'display_trace': True,       # Muestra la ruta completa de la traza
    'display_timestamp': False,  # No mostrar timestamp en cada línea
    'display_scope': True,       # Muestra el ámbito de la excepción
    'truncate_locals': 100,      # Trunca valores locales a 100 caracteres
    'timeline': True,            # Muestra la línea de tiempo de la traza
    'theme': 'monokai'           # Tema de colores (otros: 'default', 'colorful', etc.)
}

# Configurar pretty_traceback
def configure_pretty_traceback():
    if $XONSH_READABLE_TRACEBACK:
        config = $PRETTY_TRACE_CONFIG
        pretty_traceback.configure(
            display_locals=config.get('display_locals', True),
            display_trace=config.get('display_trace', True),
            display_timestamp=config.get('display_timestamp', False),
            display_scope=config.get('display_scope', True),
            truncate_locals=config.get('truncate_locals', 100),
            timeline=config.get('timeline', True),
            theme=config.get('theme', 'monokai'),
        )
        # Activar pretty-traceback
        pretty_traceback.install()
    else:
        # Desactivar pretty-traceback
        pretty_traceback.uninstall()

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
        # pretty-traceback ya mostrará automáticamente la excepción
        # ya que está instalado como hook de sys.excepthook
    elif not $XONSH_SHOW_TRACEBACK:
        pretty_traceback.uninstall()
        display_error_message()
    else:
        pretty_traceback.uninstall()
        traceback.print_exc()

    if msg:
        msg = msg if msg.endswith('\n') else msg + '\n'
        sys.stderr.write(msg)

# Reemplazar la función de xonsh
xonsh.tools.print_exception = print_exception

# Configurar pretty-traceback al cargar el xontrib
configure_pretty_traceback()
