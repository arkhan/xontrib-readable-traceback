import builtins
import xonsh.tools
from xonsh.platform import os_environ
from xonsh.tools import to_logfile_opt, display_error_message
import traceback
import pretty_traceback
import sys
import os
from colorama import init, Fore, Style

__all__ = ()
__version__ = '0.3.1'

$XONSH_SHOW_TRACEBACK=True
$XONSH_TRACEBACK_LOGFILE=None
$XONSH_READABLE_TRACEBACK=True

# pretty-traceback configuration
$READABLE_TRACE_STYLES={
        'filename': Fore.YELLOW + '{0}',
        'line': Fore.RED + Style.BRIGHT + '{0}',
        'name': '{0}',
        'source': Style.BRIGHT + Fore.GREEN + '{0}',
        'exception': Fore.RED + Style.BRIGHT + '{0}',
        'exception_name': Fore.RED + '--> ' + Fore.YELLOW + Style.BRIGHT + '{0}'}
$READABLE_TRACE_REVERSE=False
$READABLE_TRACE_ALIGN=False
$READABLE_TRACE_STRIP_PATH_ENV=False
$READABLE_TRACE_ENVVAR_ONLY=False
$READABLE_TRACE_ON_TTY=False
$READABLE_TRACE_CONSERVATIVE=False


def __flush(message):
    """
    Using sys.stderr.buffer.write for xonsh.
    """
    st = message + '\n'
    if $XONSH_READABLE_TRACEBACK:
        rep = lambda s: '' if '__amalgam__.py' in s or 'readable-traceback.xsh' in s else s+'\n'
        st = ''.join([rep(s) for s in message.split('\n')])
    sys.stderr.buffer.write(st.encode(encoding="utf-8"))
    sys.stderr.flush()


def _print_exception(msg=None, exc_info=None):
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

    # pretty-traceback hook
    tpe, v, tb = sys.exc_info() if exc_info is None else exc_info
    if $XONSH_READABLE_TRACEBACK:
        pretty_traceback.configure(
            display_link=True,
            style=$READABLE_TRACE_STYLES,
            reverse=$READABLE_TRACE_REVERSE,
            strip_path=$READABLE_TRACE_STRIP_PATH_ENV,
            suppress=[__file__]
        )
        pretty_traceback.hook()
        traceback.print_exception(tpe, v, tb)
    elif not $XONSH_SHOW_TRACEBACK:
        pretty_traceback.unhook()
        display_error_message()
    else:
        pretty_traceback.unhook()
        traceback.print_exc()
    if msg:
        msg = msg if msg.endswith('\n') else msg + '\n'
        sys.stderr.write(msg)

xonsh.tools.print_exception = _print_exception
