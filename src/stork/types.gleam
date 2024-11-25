import gleam/int
import gleam/io
import gleam/list
import pog
import stork/internal/utils

/// The errors returned by stork
pub type MigrateError {
  EnvVarError(name: String)
  UrlError(url: String)
  FileError(path: String)
  PatternError(error: String)
  FileNameError(path: String)
  CompoundError(errors: List(MigrateError))
  ContentError(path: String, error: String)
  PGOTransactionError(error: pog.TransactionError)
  PGOQueryError(error: pog.QueryError)
  MigrationNotFoundError(number: Int)
  NoResultError
  SchemaQueryError(error: String)
  NoMigrationToApplyError
}

/// Migrations are often generated by reading migration files.  
/// However, we allow you to create your own Migrations
pub type Migration {
  Migration(
    path: String,
    number: Int,
    name: String,
    queries_up: List(String),
    queries_down: List(String),
  )
}

/// Print a MigrateError to the stderr
pub fn print_migrate_error(error: MigrateError) -> Nil {
  case error {
    CompoundError(suberrors) -> {
      io.println_error("[")
      list.each(suberrors, print_migrate_error)
      io.println_error("]")
    }
    ContentError(path, message) ->
      io.println_error(
        "At [" <> path <> "]: Content wasn't right <" <> message <> ">",
      )
    EnvVarError(name) -> io.println_error("Couldn't find env var " <> name)
    FileError(path) ->
      io.println_error("Couldn't access file at path [" <> path <> "]")
    FileNameError(path) ->
      io.println_error(
        "Migration filenames should have the format <MigrationNumber>-<MigrationName>.sql ! Got: ["
        <> path
        <> "]",
      )
    MigrationNotFoundError(0) ->
      io.println_error("Migration n°0 cannot be fetched or rolled back")
    MigrationNotFoundError(number) ->
      io.println_error(
        "Migration n°" <> int.to_string(number) <> " does not exist !",
      )
    NoResultError ->
      io.println_error(
        "Got no result from DB (can't get last applied migration)",
      )
    PGOQueryError(suberror) ->
      io.println_error(utils.describe_query_error(suberror))
    PGOTransactionError(suberror) ->
      io.println_error(utils.describe_transaction_error(suberror))
    PatternError(message) -> io.println_error(message)
    UrlError(url) -> io.println_error("Database URL badly formatted: " <> url)
    SchemaQueryError(err) ->
      io.println_error("Error while querying schema : " <> err)
    NoMigrationToApplyError -> io.println_error("No migration to apply !")
  }
}
