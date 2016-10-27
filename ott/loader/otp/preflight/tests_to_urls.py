import sys

from ott.utils import otp_utils
from test_suite import ListTestSuites

def to_urls(name, hostname, port, filter, ws_path, to_file=True, file_name=None):
    #import pdb; pdb.set_trace()
    ws_url, map_url = otp_utils.get_test_urls_from_config(hostname=hostname, port=port, ws_path=ws_path)
    lts = ListTestSuites(ws_url=ws_url, map_url=map_url, filter=filter)

    if file_name or to_file:
        if file_name is None:
            # make .urls file name
            flt = "" if filter is None else "-{}".format(filter)
            file_name = "{}{}.urls".format(name, flt)

        # write urls to file
        with open(file_name, 'w') as f:
            f.write(lts.printer())
    else:
        print lts.printer()

def main():
    parser = otp_utils.get_initial_arg_parser()
    parser.add_argument('--hostname', '-hn', '-d', help="specify the hostname for the test url")
    parser.add_argument('--ws_path',  '-ws', help="OTP url path, ala 'prod' or '/otp/routers/default/plan'")
    parser.add_argument('--print',    '-p',  help="print to stdout rather than a file")
    parser.add_argument('--filename', '-f',  help="filename")
    args = parser.parse_args()

    graphs = otp_utils.get_graphs_from_config()
    if args.name == "all":
        for g in graphs:
            to_urls(g['name'], args.hostname, g['port'], args.test_suite, args.ws_path)
    elif args.name == "none" and args.hostname:
        to_urls(args.hostname, args.hostname, "80", args.test_suite, args.ws_path)
    else:
        g = otp_utils.find_graph(graphs, args.name)
        print g
        if g:
            to_urls(g['name'], args.hostname, g['port'], args.test_suite, args.ws_path)
        else:
            print "couldn't find graph {}".format(args.name)

if __name__ == '__main__':
    main()