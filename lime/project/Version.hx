package lime.project;

using StringTools;

abstract Version(SemVer) from SemVer to SemVer {
  static var VERSION = ~/^(\d+)\.(\d+)\.(\d+)(?:[-]([a-z0-9.-]+))?(?:[+]([a-z0-9.-]+))?$/i;
  @:from public static function stringToVersion(s : String) {
    if(s == null || !VERSION.match(s)) throw 'Invalid SemVer format for "$s"';
    var major = Std.parseInt(VERSION.matched(1)),
        minor = Std.parseInt(VERSION.matched(2)),
        patch = Std.parseInt(VERSION.matched(3)),
        pre   = parseIdentifiers(VERSION.matched(4)),
        build = parseIdentifiers(VERSION.matched(5));
    return new Version(major, minor, patch, pre, build);
  }

  @:from public static function arrayToVersion(a : Array<Int>) {
    a = (null == a ? [] : a).map(function(v) return v < 0 ? -v : v)
      .concat([0,0,0])
      .slice(0, 3);
    return new Version(a[0], a[1], a[2], [], []);
  }

  inline function new(major : Int, minor : Int, patch : Int, pre : Array<Identifier>, build : Array<Identifier>)
    this = {
      version : [major, minor, patch],
      pre : pre,
      build : build
    };

  public var major(get, never) : Int;
  public var minor(get, never) : Int;
  public var patch(get, never) : Int;
  public var pre(get, never) : String;
  public var hasPre(get, never) : Bool;
  public var build(get, never) : String;
  public var hasBuild(get, never) : Bool;

  public function nextMajor()
    return new Version(major+1, 0, 0, [], []);

  public function nextMinor()
    return new Version(major, minor+1, 0, [], []);

  public function nextPatch()
    return new Version(major, minor, patch+1, [], []);

  public function nextPre()
    return new Version(major, minor, patch, nextIdentifiers((this : SemVer).pre), []);

  public function nextBuild()
    return new Version(major, minor, patch, (this : SemVer).pre, nextIdentifiers((this : SemVer).build));

  public function withPre(pre : String, ?build : String)
    return new Version(major, minor, patch, parseIdentifiers(pre), parseIdentifiers(build));

  public function withBuild(build : String)
    return new Version(major, minor, patch, this.pre, parseIdentifiers(build));

  public inline function satisfies(rule : VersionRule) : Bool
    return rule.isSatisfiedBy(this);

  @:to public function toString() {
    if (this == null || this.version == null) return null;
    var v = this.version.join('.');
    if(this.pre.length > 0)
      v += '-$pre';
    if(this.build.length > 0)
      v += '+$build';
    return v;
  }

  @:op(A==B) public function equals(other : Version) {
    if(major != other.major || minor != other.minor || patch != other.patch)
      return false;
    return equalsIdentifiers(this.pre, (other : SemVer).pre);
  }

  @:op(A!=B) public function different(other : Version)
    return !(other.equals(this));

  @:op(A>B) public function greaterThan(other : Version) {
    if(hasPre && other.hasPre) {
      return major == other.major
        && minor == other.minor
        && patch == other.patch
        && greaterThanIdentifiers(this.pre, (other : SemVer).pre);
    } else if(other.hasPre) {
      if(major != other.major)
        return major > other.major;
      if(minor != other.minor)
        return minor > other.minor;
      if(patch != other.patch)
        return patch > other.patch;
      return !hasPre || greaterThanIdentifiers(this.pre, (other : SemVer).pre);
    } else if(!hasPre) {
      if(major != other.major)
        return major > other.major;
      if(minor != other.minor)
        return minor > other.minor;
      if(patch != other.patch)
        return patch > other.patch;
      return greaterThanIdentifiers(this.pre, (other : SemVer).pre);
    } else {
      return false;
    }
  }

  @:op(A>=B) public function greaterThanOrEqual(other : Version)
    return equals(other) || greaterThan(other);

  @:op(A<B) public function lessThan(other : Version)
    return !greaterThanOrEqual(other);

  @:op(A<=B) public function lessThanOrEqual(other : Version)
    return !greaterThan(other);

  inline function get_major() return this.version[0];
  inline function get_minor() return this.version[1];
  inline function get_patch() return this.version[2];


  inline function get_pre() return identifiersToString(this.pre);
  inline function get_hasPre() return this.pre.length > 0;
  inline function get_build() return identifiersToString(this.build);
  inline function get_hasBuild() return this.pre.length > 0;

  static function identifiersToString(ids : Array<Identifier>)
    return ids.map(function(id) return switch id {
        case StringId(s): s;
        case IntId(i): '$i';
      }).join('.');

  static function parseIdentifiers(s : String) : Array<Identifier>
    return (null == s ? '' : s).split('.')
      .map(sanitize)
      .filter(function(s) return s != '')
      .map(parseIdentifier);

  static function parseIdentifier(s : String) : Identifier {
    var i = Std.parseInt(s);
    return null == i ? StringId(s) : IntId(i);
  }

  static function equalsIdentifiers(a : Array<Identifier>, b : Array<Identifier>) {
    if(a.length != b.length)
      return false;
    for(i in 0...a.length)
      switch [a[i], b[i]] {
        case [StringId(a), StringId(b)] if(a != b): return false;
        case [IntId(a), IntId(b)] if(a != b): return false;
        case _:
      }
    return true;
  }

  static function greaterThanIdentifiers(a : Array<Identifier>, b : Array<Identifier>) {
    for(i in 0...a.length)
      switch [a[i], b[i]] {
        case [StringId(a), StringId(b)] if(a == b): continue;
        case [IntId(a), IntId(b)] if(a == b): continue;
        case [StringId(a), StringId(b)] if(a > b): return true;
        case [IntId(a), IntId(b)] if(a > b): return true;
        case [StringId(_), IntId(_)]: return true;
        case _: return false;
      }
    return false;
  }

  static function nextIdentifiers(identifiers : Array<Identifier>) : Array<Identifier> {
    var identifiers = identifiers.copy(),
        i = identifiers.length;
    while(--i >= 0) switch (identifiers[i]) {
      case IntId(id):
        identifiers[i] = IntId(id+1);
        break;
      case _:
    }
    if(i < 0) throw 'no numeric identifier found in $identifiers';
    return identifiers;
  }

  static var SANITIZER = ~/[^0-9A-Za-z-]/g;
  static function sanitize(s : String) : String
    return SANITIZER.replace(s, '');
}

enum Identifier {
  StringId(value : String);
  IntId(value : Int);
}

typedef SemVer = {
  version : Array<Int>,
  pre : Array<Identifier>,
  build : Array<Identifier>
}

abstract VersionRule(VersionComparator) from VersionComparator to VersionComparator {
  static var VERSION = ~/^(>=|<=|[v=><~^])?(\d+|[x*])(?:\.(\d+|[x*]))?(?:\.(\d+|[x*]))?(?:[-]([a-z0-9.-]+))?(?:[+]([a-z0-9.-]+))?$/i;
  @:from public static function stringToVersionRule(s : String) : VersionRule {
    var ors = s.split("||").map(function(comp) {
      comp = comp.trim();
      var p = comp.split(" - ");
      return if(p.length == 1) {
        comp = comp.trim();
        p = (~/\s+/).split(comp);
        if(p.length == 1) {
          if(comp.length == 0) {
            GreaterThanOrEqualVersion(Version.arrayToVersion([0,0,0]).withPre(VERSION.matched(5), VERSION.matched(6)));
          } else if(!VERSION.match(comp)) {
            throw 'invalid single pattern "$comp"';
          } else {
            // one term pattern
            var v  = versionArray(VERSION),
                vf = v.concat([0, 0, 0]).slice(0, 3);
            switch [VERSION.matched(1), v.length] {
              case ["v", 0], ["=", 0], ["", 0], [null, 0]:
                GreaterThanOrEqualVersion(Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6)));
              case ["v", 1], ["=", 1], ["", 1], [null, 1]:
                var version = Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6));
                AndRule(
                  GreaterThanOrEqualVersion(version),
                  LessThanVersion(version.nextMajor())
                );
              case ["v", 2], ["=", 2], ["", 2], [null, 2]:
                var version = Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6));
                AndRule(
                  GreaterThanOrEqualVersion(version),
                  LessThanVersion(version.nextMinor())
                );
              case ["v", 3], ["=", 3], ["", 3], [null, 3]:
                EqualVersion(Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6)));
              case [">", _]:
                GreaterThanVersion(Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6)));
              case [">=", _]:
                GreaterThanOrEqualVersion(Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6)));
              case ["<", _]:
                LessThanVersion(Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6)));
              case ["<=", _]:
                LessThanOrEqualVersion(Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6)));
              case ["~", 1]:
                var version = Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6));
                AndRule(
                  GreaterThanOrEqualVersion(version),
                  LessThanVersion(version.nextMajor())
                );
              case ["~", 2], ["~", 3]:
                var version = Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6));
                AndRule(
                  GreaterThanOrEqualVersion(version),
                  LessThanVersion(version.nextMinor())
                );
              case ["^", 1]:
                var version = Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6));
                AndRule(
                  GreaterThanOrEqualVersion(version),
                  LessThanVersion(version.nextMajor())
                );
              case ["^", 2]:
                var version = Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6));
                AndRule(
                  GreaterThanOrEqualVersion(version),
                  LessThanVersion(version.major == 0 ? version.nextMinor() : version.nextMajor())
                );
              case ["^", 3]:
                var version = Version.arrayToVersion(vf).withPre(VERSION.matched(5), VERSION.matched(6));
                AndRule(
                  GreaterThanOrEqualVersion(version),
                  LessThanVersion(version.major == 0 ? (version.minor == 0 ? version.nextPatch() : version.nextMinor()) : version.nextMajor())
                );
              case [p, _]: throw 'invalid prefix "$p" for rule $comp';
            };
          }
        } else if(p.length == 2) {
          if(!VERSION.match(p[0]))
            throw 'left hand parameter is not a valid version rule "${p[0]}"';
          var lp  = VERSION.matched(1),
              lva = versionArray(VERSION),
              lvf = lva.concat([0, 0, 0]).slice(0, 3),
              lv  = Version.arrayToVersion(lvf).withPre(VERSION.matched(5), VERSION.matched(6));

          if(lp != ">" && lp != ">=")
            throw 'invalid left parameter version prefix "${p[0]}", should be either > or >=';
          if(!VERSION.match(p[1]))
            throw 'left hand parameter is not a valid version rule "${p[0]}"';
          var rp  = VERSION.matched(1),
              rva = versionArray(VERSION),
              rvf = rva.concat([0, 0, 0]).slice(0, 3),
              rv  = Version.arrayToVersion(rvf).withPre(VERSION.matched(5), VERSION.matched(6));
          if(rp != "<" && rp != "<=")
            throw 'invalid right parameter version prefix "${p[1]}", should be either < or <=';

          AndRule(
            lp == ">" ? GreaterThanVersion(lv) : GreaterThanOrEqualVersion(lv),
            rp == "<" ? LessThanVersion(rv) : LessThanOrEqualVersion(rv)
          );
        } else {
          throw 'invalid multi pattern $comp';
        }
      } else if(p.length == 2) {
        if(!VERSION.match(p[0]))
            throw 'left range parameter is not a valid version rule "${p[0]}"';
        if(VERSION.matched(1) != null && VERSION.matched(1) != "")
            throw 'left range parameter should not be prefixed "${p[0]}"';
        var lv = Version.arrayToVersion(versionArray(VERSION).concat([0, 0, 0]).slice(0, 3)).withPre(VERSION.matched(5), VERSION.matched(6));
        if(!VERSION.match(p[1]))
            throw 'right range parameter is not a valid version rule "${p[1]}"';
        if(VERSION.matched(1) != null && VERSION.matched(1) != "")
            throw 'right range parameter should not be prefixed "${p[1]}"';
        var rva = versionArray(VERSION),
            rv = Version.arrayToVersion(rva.concat([0, 0, 0]).slice(0, 3)).withPre(VERSION.matched(5), VERSION.matched(6));

        if(rva.length == 1)
          rv = rv.nextMajor();
        else if(rva.length == 2)
          rv = rv.nextMinor();

        AndRule(
          GreaterThanOrEqualVersion(lv),
          rva.length == 3 ? LessThanOrEqualVersion(rv) : LessThanVersion(rv)
        );
      } else {
        throw 'invalid pattern "$comp"';
      }
    });

    var rule = null;
    while(ors.length > 0) {
      var r = ors.pop();
      if(null == rule)
        rule = r;
      else
        rule = OrRule(r, rule);
    }
    return rule;
  }

  static var IS_DIGITS = ~/^\d+$/;
  static function versionArray(re : EReg) {
    var arr = [],
        t;
    for(i in 2...5) {
      t = re.matched(i);
      if(null != t && IS_DIGITS.match(t))
        arr.push(Std.parseInt(t));
      else
        break;
    }
    return arr;
  }

  public static function versionRuleIsValid(rule : String)
    return try stringToVersionRule(rule) != null catch(e : Dynamic) false;

  public function isSatisfiedBy(version : Version) : Bool {
    return switch this {
      case EqualVersion(ver):
        version == ver;
      case GreaterThanVersion(ver):
        version > ver;
      case GreaterThanOrEqualVersion(ver):
        version >= ver;
      case LessThanVersion(ver):
        version < ver;
      case LessThanOrEqualVersion(ver):
        version <= ver;
      case AndRule(a, b):
        (a : VersionRule).isSatisfiedBy(version) && (b : VersionRule).isSatisfiedBy(version);
      case OrRule(a, b):
        (a : VersionRule).isSatisfiedBy(version) || (b : VersionRule).isSatisfiedBy(version);
    };
  }

  @:to public function toString() : String
    return switch ((this : VersionComparator)) {
      case EqualVersion(ver):
        ver;
      case GreaterThanVersion(ver):
        '>$ver';
      case GreaterThanOrEqualVersion(ver):
        '>=$ver';
      case LessThanVersion(ver):
        '<$ver';
      case LessThanOrEqualVersion(ver):
        '<=$ver';
      case AndRule(a, b): {
        (a : VersionRule) + ' ' + (b : VersionRule);
      }
      case OrRule(a, b):
        (a : VersionRule) + ' || ' + (b : VersionRule);
    };
}

enum VersionComparator {
  EqualVersion(ver : Version);
  GreaterThanVersion(ver : Version);
  GreaterThanOrEqualVersion(ver : Version);
  LessThanVersion(ver : Version);
  LessThanOrEqualVersion(ver : Version);
  AndRule(a : VersionComparator, b : VersionComparator);
  OrRule(a : VersionComparator, b : VersionComparator);
}