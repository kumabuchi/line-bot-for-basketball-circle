create table users (
  id integer primary key,
  name text,
  line_user_id text,
  profile_image_url text,
  random text,
  remind boolean,
  request boolean,
  created_at,
  updated_at
);

create table schedules (
  id integer primary key,
  description text,
  start datetime,
  end datetime,
  is_cancelled boolean,
  created_at,
  updated_at
);

create table participations (
  id integer primary key,
  user_id integer,
  schedule_id integer,
  propriety integer,
  created_at,
  updated_at
);
