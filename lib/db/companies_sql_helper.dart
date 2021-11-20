/* SQL запросы для базы по фирмам
*/
List<String> companiesSQLHelper() {
  List<String> queries = [];
  String catalogueQuery = 'create table if not exists catalogue(' +
      'id integer primary key autoincrement not null,' +
      ' name text,' +
      ' count integer,' +
      ' icon text,' +
      ' searchTerms text' +
      ')';
  queries.add(catalogueQuery);
  String catsQuery = 'create table if not exists cats(' +
      'id integer primary key autoincrement not null,' +
      ' catId integer,' +
      ' clientId integer' +
      ')';
  queries.add(catsQuery);
  String catContposQuery = 'create table if not exists cat_contpos(' +
      'id integer primary key autoincrement not null,' +
      ' catId integer,' +
      ' clientId integer,' +
      ' position integer' +
      ')';
  queries.add(catContposQuery);
  String addressesQuery = 'create table if not exists addresses(' +
      'id integer primary key autoincrement not null,' +
      ' postalCode text,' +
      ' country text,' +
      ' state text,' +
      ' county text,' +
      ' city text,' +
      ' district text,' +
      ' subdistrict text,' +
      ' street text,' +
      ' houseNumber text,' +
      ' addressLines text,' +
      ' additionalData text,' +
      ' latitude decimal(30, 25),' +
      ' longitude decimal(30, 25),' +
      ' place text,' +
      ' branchesCount integer,' +
      ' searchTerms text' +
      ')';
  queries.add(addressesQuery);
  String orgsQuery = 'create table if not exists orgs(' +
      'id integer primary key autoincrement not null,' +
      ' name text,' +
      ' logo text,' +
      ' resume text,' +
      ' branches integer,' +
      ' phones integer,' +
      ' reg integer,' +
      ' rating decimal(2,1),' +
      ' searchTerms text' +
      ')';
  queries.add(orgsQuery);
  String branchesQuery = 'create table if not exists branches(' +
      'id integer primary key autoincrement not null,' +
      ' client integer,' +
      ' name text,' +
      ' address integer,' +
      ' addressAdd text,' +
      ' site text,' +
      ' email text,' +
      ' wtime text,' +
      ' reg integer,' +
      ' position integer,' +
      ' searchTerms text' +
      ')';
  queries.add(branchesQuery);
  String phonesQuery = 'create table if not exists phones(' +
      'id integer primary key autoincrement not null,' +
      ' client integer,' +
      ' branch integer,' +
      ' prefix integer,' +
      ' number text,' +
      ' digits text,' +
      ' whata integer,' +
      ' comment text,' +
      ' position integer,' +
      ' searchTerms text' +
      ')';
  queries.add(phonesQuery);
  return queries;
}