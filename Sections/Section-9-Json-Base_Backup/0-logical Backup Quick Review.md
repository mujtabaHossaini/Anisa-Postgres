##  Instant PostgreSQL Backup and Restore How-to

Welcome to *PostgreSQL Backup and Restore How-to*. Here, we'll explore the proper, secure, and reliable methods for preserving mission-critical data. More importantly, we'll tell you how to get that data back! PostgreSQL provides several handy tools for both basic SQL exports and binary backup, which we will combine with more advanced techniques for a complete toolkit. By the end of this book, you should have a full array of options that you can automate for worry-free backups.

 

## Getting a basic export (Simple)

------

We will start with `pg_dumpall`, the most basic PostgreSQL backup tool. This single command-line utility can export the entire database instance at once. We want to start with this particular command, because it preserves important information such as users, roles, and passwords. Later, we will only use it to obtain this important metadata.

### Getting ready

Before we begin backing up our database, we should have a database! Since we have installed both PostgreSQL and the `Contrib` tools, we should have everything we need to get started with. To make things easier, we will export a single environment variable to run all commands as the `postgres` user. This user owns the database instance in default installs. Exporting this variable lets you act as the `postgres` user for all future examples. Later, we can use the `createdb` utility to create an empty database for our backup experimentation. The `pgbench` utility will be our source of data, as shown in the following code snippet, since backing up an empty database is hard to verify upon restore:

```markup
$> export PGUSER=postgres
$> createdb sample
$> pgbench -i -s 50 sample
```



Now we have a database named `sample` with several tables full of generated data. Since the default row count for the tool is 100,000, a scale of `50` provides a table with five million rows that we can use to verify the backup processing time required. We can also verify the restored database by checking for the existence of the generated tables and their content. If this scale is too large, feel free to use a smaller scale to follow along.

### Tip

The `sample` database will be the basis for all subsequent data export examples. Unless otherwise specified, it always starts with a fresh database. Again, you can use the suggested scale size here, or choose your own.

### How to do it...

Creating a backup this way requires a single command, as follows:

1. Make sure you have opened a **Command Prompt** console as a local user on your Linux system, and type the following command:

   ```markup
   $> pg_dumpall -f backup.sql
   ```

   

### How it works...

The `pg_dumpall` utility produces what should be a full  of all database objects including `users`, `schemas`, and `data`, as a single very large SQL file. Our example directed the SQL output to a file named `backup.sql`, but any name is valid, so long as we can remember it later.

### There's more...

Though the venerable `--help` command-line switch always lists the full capabilities available to us, the more important of these deserve more discussion.

#### Restoring the export

Before we get much further, we should quickly explain how to restore the SQL file you just produced. Our other recipes are more complex and require separate sections, but restoring a `pg_dumpall` export is very easy. The `psql` command is used for running SQL files. Since this is just a SQL file, you can run it directly against the database. Try the following:

```markup
$> psql -f backup.sql postgres
```



The `-f` switch tells PostgreSQL that we want to execute our backup file against the database `postgres`, which is a placeholder. The `psql` command expects a database name, so we have provided a simple default. Your backup will still restore properly, for example, creating and filling the sample database. This is because the backup also contains database creation commands and more commands to change database targets so that all data goes where it should. Like we said, this is the easiest backup method PostgreSQL has.

#### Exporting global objects

Though the SQL export itself is perfectly valid for restore, many administrators prefer to use the `pg_dumpall` export to obtain the globally stored objects such as `users`, `roles`, and `passwords` only, and use other tools for things such as tables and other data. To get this global data alone, the `-g` switch tells `pg_dumpall` that is all we wanted. Type the following command to get only global objects:

```markup
$> pg_dumpall -g -f globals.sql
```



We will be using the previous command frequently for just getting global objects.

#### Compressed backups

Unfortunately `pg_dumpall` cannot directly compress its output; it is a very basic tool. If we have an extremely large database, other UNIX commands will also be necessary. For example, the following command will compress the dump using a parallel algorithm while it is being produced, to greatly reduce backup time and size:

```markup
$> pg_dumpall | gzip > backup.sql.gz
```



#### Naming backups

Note that in all of our examples thus far, we have named the backup rather poorly. It is a better practice to use the `-f` switch to provide a name that follows a specific naming scheme. Backup files should always include at least one contextual clue, the date on which the backup was taken, and possibly the time. The following is a better example:

```markup
$> pg_dumpall -f production_2013-02-15.sql
```



 

## Partial database exports (Simple)

------

Backups are not limited to the whole running instance. Each database can be dumped individually with the `pg_dump` utility.

### Getting ready

Please refer to the *Getting a basic export (Simple)* recipe on preparing a `sample` database.

### How to do it...

This time, we will need to execute the following commands on the command line:

1. First, type the following command to obtain global objects such as `users`, `groups`, and `passwords`:

   ```markup
   $> pg_dumpall -g -f globals.sql
   ```

   

2. Next, this command will create a `sample` database:

   ```markup
   $> pg_dump -f sample_backup.sql sample
   ```

   

### How it works...

This took a bit more effort, but not much. Because the `pg_dump` utility can only back up one database at a time, we don't get global objects such as `users` and `groups`. Thus we must also use `pg_dumpall` if we want to restore with the same users and groups.

But what about the SQL dump itself? Just like `pg_dumpall`, `pg_dump` uses the `-f` switch to send output to a named file. The last parameter is a positional parameter. Most PostgreSQL tools are set up to assume the last parameter without a flag is actually a database name. In this case, our `sample` database is what we are exporting to SQL.

### There's more...

Why do we even need `pg_dump` if it can only back up one database at a time? It seems silly at first, but by doing so, we unlock several additional capabilities, not the least of which is the ability to *restore* a database independently of its original name. There are also significant improvements and several new command-line options.

#### Compressed exports

Unlike `pg_dumpall`, which could not compress backup output, `pg_dump` makes it quite simple by using the following command:

```markup
$> pg_dump -Fc -f sample_backup.pgr sample
```



The `-F` switch changes the output format. In this case, we chose `c` for custom output. The PostgreSQL custom output format is a proprietary compressed export that you will not be able to read, but requires much less space than the default SQL output. The restore tool actually prefers this format, and requires it for advanced options such as parallel database restore, which we will be discussing later.

#### Table-only exports

Not only can we restrict a backup to a single database, but `pg_dump` also provides an option to back up one or more tables. Our `sample` database contains a `pgbench_accounts` table. Let's export this table by itself with the following command:

```markup
$> pg_dump -t pgbench_accounts -f accounts_backup.sql sample
```



Exporting individual tables means they can also be restored in other databases or archived for later. We can also use the `-t` switch as often as we like, keeping several related tables together. However, keep in mind that getting a complete list of related tables is often difficult. Views, triggers, stored procedures, and other related objects may also be necessary to retain full functionality of these objects upon restore. When you use this option, you only get the objects you requested, and nothing else.

#### Schema-only exports

As with tables, schemas themselves (collections of related objects) can be exported. Our `sample` database only has the `public` schema, which we can export with the `-n` switch, as shown in the following command:

```markup
$> pg_dump -n public -f public_namespace_backup.sql sample
```



Larger instances sometimes have schemas for each application or client. With the option to export these separately, they can be moved between databases, backed up or restored independently of the entire database, or archived.

#### Data and schema-only exports

Tables, views, and other objects contained in the schema can also be exported with or without the data. Perhaps we want to track schema changes, for example, as shown in the following command:

```markup
$> pg_dump -s -f schema_backup.sql sample
```



The opposite is also true. We may not need or want the schema definitions. The `-a` flag gives us only table data using the following command:

```markup
$> pg_dump -a -f data_backup.sql sample
```



Again, remember that performing an export of a single object may lose a lot of dependent elements (for example, views). Don't use the single object export options if you need this information together.

Either of these options can be combined with table or schema exports. Let's grab only the data for the `pgbench_branches` table.

```markup
$> pg_dump -a -t pgbench_branches -f branch_data.sql sample
```



 

## Restoring a database export (Simple)

------

Once a backup is taken, we need to know how to use it to restore the database to working order. Once again, PostgreSQL provides the `pg_restore` utility to do all of the hard work.

### Getting ready

Please refer to the *Getting a basic export (Simple)* recipe on preparing a `sample` database. The `pg_restore` tool gains the most functionality with the **custom** export format, so we will use that for the following example. These commands should produce a simple SQL export of our databases. We will give the backup a `.pgr` extension, indicating that it is a PostgreSQL backup file, as shown in the following command:

```markup
$> pg_dump -Fc -f sample_backup.pgr sample
$> pg_dumpall -g -f globals.sql
```



Once these files are safely stored elsewhere, revert the database to a fresh install.

The normal procedure to do this is a bit complex, so for now, we can cheat a little. Simply drop the `sample` database with the following command, and we can continue:

```markup
$> dropdb sample
```



### How to do it...

The `pg_restore` tool is not quite analogous to `pg_dump`. It is more of a sophisticated backup playback engine. Since we are working with a partial export, there are a few extra steps to fully restore everything as follows:

1. Again, start by obtaining our global objects:

   ```markup
   $> psql -f globals.sql postgres
   ```

   

2. Next, create the sample database:

   ```markup
   $> createdb sample
   ```

   

3. Finally, use the following restoration command:

   ```markup
   $> pg_restore -d sample sample_backup.pgr
   ```

   

### How it works...

There is a bit of new material here. We started by using the `psql` utility to execute commands in the `globals.sql` file. Remember, output of `pg_dumpall` is just in SQL format, so we can use PostgreSQL's default SQL execution command. We can connect to the `postgres` database, since it always exists as a root for new database installations. This creates the global objects such as `users` and `groups` that we always want to preserve.

We then needed the `sample` database to exist, so we used `createdb`, another PostgreSQL utility we have used before. This time, it provides a target for `pg_restore`. By using the `-d` flag, our backup is restored directly into the `sample` database instead of any preexisting defaults. The last parameter is similar to how we specify a database name with `pg_dump` or `psql`. But for `pg_restore`, the last unnamed parameter is assumed to be a database backup to restore.

### There's more...

That was admittedly much more complicated than simply using `pg_dumpall` to export everything, and `psql` to restore it including database names. However, now we are using much more powerful tools and gaining even further flexibility.

#### Parallel database restore

Since we are using PostgreSQL Version 8.4 or higher, the `pg_restore` utility includes the ability to execute parts of a backup file in parallel. While data is restoring in one table, indexes could be created in another. We could have restored our `sample` database using the following command:

```markup
$> pg_restore -j 4 -d sample sample_backup.pgr
```



This would invoke four restore jobs (`-j`) simultaneously. With enough CPUs, restores finish several times faster than the default linear process. Index and primary key creation are very CPU intensive.

#### Database targeting

Note how we always specify the `restore` database. We could just as easily restore the database twice with different names each time! Each database is independent of the other. The following command lines show how we can restore the database twice:

```markup
$> createdb sample
$> createdb extra
$> pg_restore -d sample sample_backup.pgr
$> pg_restore -d extra sample_backup.pgr
```



This is a perfect tool to experiment with production data safely or to restore an old backup next to a production database, and transfer data between them.

#### Partial database restores

Even though our export is of the entire `sample` database, we could restore only portions of it, or only the schema, or only the data. Much like `pg_dump`, all these options are available, and `pg_restore` is smart enough to ignore irrelevant parts of a source backup. The following command would only restore the `pgbench_tellers` table:

```markup
$> pg_restore -d sample -t pgbench_tellers sample_backup.pgr
```



### Note

Remember to create your databases with `createdb` before restoring them!

 

## Obtaining a binary backup (Simple)

------

Another backup method available to PostgreSQL is a `base` backup, which consists of the actual data files themselves. These kinds of backups do not need to be restored, only uncompressed or copied. Using them can be more complicated, but they can be ready much faster depending on the database size. The developers have kindly provided `pg_basebackup` as a simple starting point.

### Getting ready

Please refer to the *Getting a basic export (Simple)* recipe on preparing a `sample` database.

Next we need to modify the `postgresql.conf` file for our database to run in the proper mode for this type of backup. Change the following configuration variables:

```markup
wal_level = archive
max_wal_senders = 5
```



Then we must allow a super user to connect to the `replication` database, which is used by `pg_basebackup`. We do that by adding the following line to `pg_hba.conf`:

```markup
local replication postgres peer
```



Finally, restart the `database` instance to commit the changes.

### How to do it...

Though it is only one command, `pg_basebackup` requires at least one switch to obtain a binary backup, as shown in the following step:

1. Execute the following command to create the backup in a new directory named `db_backup`:

   ```markup
   $> pg_basebackup -D db_backup -x
   ```

   

### How it works...

For PostgreSQL, **WAL** stands for **Write Ahead Log**. By changing `wal_level` to `archive`, those logs are written in a format compatible with `pg_basebackup` and other replication-based tools.

By increasing `max_wal_senders` from the default of zero, the database will allow tools to connect and request data files. In this case, up to five streams can request data files simultaneously. This maximum should be sufficient for all but the most advanced systems.

The `pg_hba.conf` file is essentially a connection **access control list** (**ACL**). Since `pg_basebackup` uses the replication protocol to obtain data files, we need to allow local connections to request replication.

Next, we send the backup itself to a directory (`-D`) named `db_backup`. This directory will effectively contain a complete  of the binary files that make up the database.

Finally, we added the `-x` flag to include transaction logs (`xlogs`), which the database will require to start, if we want to use this backup. When we get into more complex scenarios, we will exclude this option, but for now, it greatly simplifies the process.

### There's more...

The `pg_basebackup` tool is actually fairly complicated. There is a lot more involved under the hood.

#### Viewing backup progress

For manually invoked backups, we may want to know how long the process might take, and its current status. Luckily, `pg_basebackup` has a progress indicator, which does that by using the following command:

```markup
$> pg_basebackup -P -D db_backup
```



Like many of the other switches, `-P` can be combined with tape archive format, standalone backups, database clones, and so on. This is clearly not necessary for automated backup routines, but could be useful for one-off backups monitored by an administrator.

#### Compressed tape archive backups

Many binary backup files come in the **TAR** (**Tape Archive**) format, which we can activate using the `-f` flag and setting it to `t` for TAR. Several Unix backup tools can directly process this type of backup, and most administrators are familiar with it.

If we want a compressed output, we can set the `-z` flag, especially in the case of large databases. For our `sample` database, we should see almost a 20x compression ratio. Try the following command:

```markup
$> pg_basebackup -Ft -z -D db_backup
```



The backup file itself will be named `base.tar.gz` within the `db_backup` directory, reflecting its status as a compressed tape archive. In case the database contains extra tablespaces, each becomes a separate compressed archive. Each file can be extracted to a separate location, such as a different set of disks, for very complicated database instances.

For the sake of this example, we ignored the possible presence of extra tablespaces than the `pg_default` default included in every installation. User-created tablespaces will greatly complicate your backup process.

#### Making the backup standalone

By specifying `-x`, we tell the database that we want a "complete" backup. This means we could extract or  the backup anywhere and start it as a fully qualified database. As we mentioned before, the flag means that you want to include transaction logs, which is how the database recovers from crashes, checks integrity, and performs other important tasks. The following is the command again, for reference:

```markup
$> pg_basebackup -x -D db_backup
```

When combined with the TAR output format and compression, standalone binary backups are perfect for archiving to tape for later retrieval, as each backup is compressed and self-contained. By default, `pg_basebackup` does not include transaction logs, because many (possibly most) administrators back these up separately. These files have multiple uses, and putting them in the basic backup would duplicate efforts and make backups larger than necessary.

We include them at this point because it is still too early for such complicated scenarios. We will get there eventually, of course.

#### Database clones

Because `pg_basebackup` operates through PostgreSQL's replication protocol, it can execute remotely. For instance, if the database was on a server named `Production`, and we wanted a  on a server named `Recovery`, we could execute the following command from `Recovery`:

```markup
$> pg_basebackup -h Production -x -D /full/db/path
```



For this to work, we would also need this line in `pg_hba.conf` for `Recovery`:

```markup
host replication postgres Recovery trust
```



Though we set the authentication method to `trust`, this is not recommended for a production server installation. However, it is sufficient to allow `Recovery` to  all data from `Production`. With the `-x` flag, it also means that the database can be started and kept online in case of emergency. It is a backup *and* a running server.

#### Parallel compression

Compression is very CPU intensive, but there are some utilities capable of threading the process. Tools such as `pbzip2` or `pigz` can do the compression instead. Unfortunately, this only works in the case of a single tablespace (the default one; if you create more, this will not work). The following is the command for compression using `pigz`:

```markup
$> pg_basebackup -Ft -D - | pigz -j 4 > db_backup.tar.gz
```

It uses four threads of compression, and sets the backup directory to standard output (`-`) so that `pigz` can process the output itself.

 

## Stepping into TAR backups (Intermediate)

------

For a very long time, the Unix `tar` command was one of the only methods for obtaining a full binary backup of a PostgreSQL database. This is still the case for more advanced installations which may make use of filesystem snapshots, extensively utilize tablespaces, or otherwise disrupt the included management tools. For these advanced scenarios and more, `tar` is indispensable for circumventing or augmenting the provided tools.

### Getting ready

Please refer to the *Getting a basic export (Simple)* recipe on preparing a `sample` database.

For the purposes of this example, we will assume that the database directory is `/db`, and the archived files will go to `/archive`. Based on this, we need to modify the `postgresql.conf` file to archive transaction logs during the backup. Change the following configuration variables:

```markup
archive_mode = on
archive_command = 'test -f /archive/%f || cp %p /archive/%f'
```



After PostgreSQL is restarted, the database will be ready for a `tar` backup.

### How to do it...

Creating a `tar` backup is done with the following three basic steps, plus a fourth set of commands that are considered as good practice:

1. First, tell PostgreSQL to enter `backup` mode:

   ```markup
   $> psql -c "SELECT pg_start_backup('label');" postgres
   ```

   

2. Next, we produce the actual backup with `tar`, instead of `pg_dump` or `pg_basebackup`:

   ```markup
   $> tar -c -z -f backup.tar.gz /db
   ```

   

3. Finally, we tell the database to end `backup` mode:

   ```markup
   $> psql -c "SELECT pg_stop_backup();" postgres
   ```

   

4. We also need the transaction logs archived during the backup. Type these commands as shown:

   ```markup
   $> recent=$(ls -r /archive/*.backup | head -1)
   $> bstart=$(grep 'START WAL' $recent | sed 's/.* //; s/)//;')
   $> echo $bstart > /tmp/MANIFEST
   $> echo $recent >> /tmp/MANIFEST
   $> find /archive -newer /archive/$bstart \
     ! -newer $recent >> /tmp/FILES
   $> sed 's%/.*/%%' /tmp/MANIFEST | sort | uniq \
     > /archive/MANIFEST
   $> tar -C /archive -cz -f archive.tar.gz \
     –files-from=/archive/MANIFEST
   ```

   

Obviously, much of this can (and should) be scripted. These commands were designed for a standard Linux system. If you are using BSD or another variant, you many need to convert them before doing this yourself.

### How it works...

The `tar` command for creating a backup itself is fairly simple: creating (`-c`) a `.gzip` compressed (`-z`) file named `backup.tar.gz` from the contents of `/db`, wherever our database lives. Of course, these data files are likely to be changing while they're being backed up, because the process itself can take minutes or hours depending on the size of the database.

Because of this, we call `pg_start_backup` to start the backup process. To begin with, it will commit pending writes to the database files (checkpoint). Afterwards, it will continue normal operation, but will also keep track of which transaction files were produced during the backup. This is important for future restores.

Next we invoke `pg_stop_backup` to complete the backup. This command not only finishes the backup, but also creates a file with a `.backup` extension that identifies the first and last archive logs necessary to restore the database to full working order. We need the first, last, and every transaction log in between to restore, which is what the last set of commands is for.

Knowing that the most recent `.backup` file archived by the database contains this information, we parse it using various Unix commands to identify every file between the first marked archive log, and the end of the backup itself. No file is older than the `.backup` file. All of these files are required to fully restore the database, and the process itself is fairly complicated.

We highly recommend implementing a more robust and tested version of the outlined steps, or using a preexisting backup library or third-party tool. For example, OmniPITR is often recommended. Our quick and dirty method works, but it should be fairly obvious why `pg_basebackup` automates and abstracts away most of the complexity in our example. We gain *flexibility* here, not ease of use.

### There's more...

Now we should discuss exactly what kind of flexibility we may gain.

#### Parallel compression

Compressing files is very CPU intensive; `pigz` and `pbzip2` are still very handy, and `tar` works very well with external utilities. We can alter the archival command for the `/db` directory from the previous commands with the `-I` flag to choose our own compression program, as shown in the following command:

```markup
$> tar -c -I pigz -f backup.tar.gz /db
```



Alternatively, since `pigz` can take parameters for choosing the number of threads, or because certain versions of `tar` don't support the `-I` flag, we can send the output of `tar` to `pigz` instead by using the following command:

```markup
$> tar -c /db | pigz -p 4 > backup.tar.gz
```



Unlike `pg_basebackup`, these `tar` commands work with complex databases that make extensive use of tablespaces. Each tablespace can be handled separately and compressed in parallel, drastically reducing compression time.

Some may argue that `pg_basebackup` does support tablespaces, and it does create `.tar.gz` files for every user-created tablespace in the database along with `base.tar.gz`. However, the `tar` output format of this tool will not stream to standard output if there are user-created tablespaces. This means that our trick of capturing the stream with `pigz` would not work in such advanced systems. Hence, we used `tar` in this example.

#### Making a tar backup standby-ready

With PostgreSQL, a database in standby or streaming mode will not have its own transaction logs while recovery is in progress, since it uses some other source of archived transaction logs to apply changes to the database. This means that backing these files up is often excessive. Remember, we mentioned that `pg_basebackup` omits them by default for similar reasons. Thankfully, `tar` can also exclude them, or any other paths. Again, we will modify the `/db` backup command as follows:

```markup
$> tar -c -z -f backup.tar.gz --exclude=pg_xlog  /db
```

Now, if the `backup.tar.gz` file is uncompressed, it can only be used for standby or streaming replication.

