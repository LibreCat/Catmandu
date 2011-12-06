package Dancer::Plugin::Piwik;

our $VERSION = '0.1';

use strict;
use warnings;
use Dancer::Plugin;
use Dancer qw(:syntax);

my $setting = plugin_setting;

my $tracking_js;

if ($setting->{async}) {
    $tracking_js = <<JS
<script type="text/javascript">
    var _paq = _paq || [];
    (function(){
        var u=(("https:" == document.location.protocol) ? "https://$setting->{url}/" : "http://$setting->{url}/");
        _paq.push(['setSiteId', $setting->{id_site}]);
        _paq.push(['setTrackerUrl', u+'piwik.php']);
        _paq.push(['trackPageView']);
        var d=document,
            g=d.createElement('script'),
            s=d.getElementsByTagName('script')[0];
            g.type='text/javascript';
            g.defer=true;
            g.async=true;
            g.src=u+'piwik.js';
            s.parentNode.insertBefore(g,s);
    })();
</script>
JS
} else {
    $tracking_js = <<JS
<script type="text/javascript">
    var pkBaseURL = (("https:" == document.location.protocol) ? "https://$setting->{url}/" : "http://$setting->{url}/");
    document.write(unescape("%3Cscript src='" + pkBaseURL + "piwik.js' type='text/javascript'%3E%3C/script%3E"));
</script>
<script type="text/javascript">
    try {
        var piwikTracker = Piwik.getTracker(pkBaseURL + "piwik.php", $setting->{id_site});
        piwikTracker.trackPageView();
        piwikTracker.enableLinkTracking();
    } catch(err) {}
</script>
JS
}

before_template sub {
    $_[0]->{piwik} = 1;
    $_[0]->{piwik_tracking_js} = $tracking_js;
};

register piwik_tracking_js => sub {
    $tracking_js;
};

register_plugin;

1;
