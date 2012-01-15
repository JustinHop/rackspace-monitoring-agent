{
  'targets': [
    {
      'target_name': 'luvit',
      'type': 'static_library',
      'dependencies': [
        'http_parser/http_parser.gyp:http_parser',
        'uv/uv.gyp:uv',
        'zlib.gyp:zlib',
        'yajl.gyp:yajl',
        'openssl.gyp:openssl',
        'lua.gyp:lua',
      ],

      'defines': [
        '_LARGEFILE_SOURCE',
        '_FILE_OFFSET_BITS=64',
      ],

      'sources': [
        'luvit/src/lconstants.c',
        'luvit/src/lenv.c',
        'luvit/src/lhttp_parser.c',
        'luvit/src/lyajl.c',
        'luvit/src/los.c',
        'luvit/src/luv.c',
        'luvit/src/luv_dns.c',
        'luvit/src/luv_fs.c',
        'luvit/src/luv_fs_watcher.c',
        'luvit/src/luv_handle.c',
        'luvit/src/luv_misc.c',
        'luvit/src/luv_pipe.c',
        'luvit/src/luv_process.c',
        'luvit/src/luv_stream.c',
        'luvit/src/luv_tcp.c',
        'luvit/src/luv_timer.c',
        'luvit/src/luv_tty.c',
        'luvit/src/luv_udp.c',
        'luvit/src/utils.c',
      ],

      'include_dirs': [
          'luvit/src',
          # uv_inet_ntop is not provided by libuv,
          # but instead is a macro to a c-ares function
          'uv/src/ares',
      ],

      'direct_dependent_settings': {
        'include_dirs': [
          'luvit/src',
        ],
      },
    },
  ],
}

