# Test Stand Runbook

## Быстрое подключение на стенде

```bash
cd /Users/valeriypopov/redmine_status_alias
sudo scripts/link_to_redmine.sh /home/red2mine/20240627/red2mine
sudo scripts/migrate_plugin.sh /home/red2mine/20240627/red2mine
```

После этого перезапустите Rails/Passenger/Puma-процесс Redmine.

## Проверка

1. Войдите администратором.
2. Откройте настройки плагина `Redmine Status Alias`.
3. Включите плагин.
4. Выберите клиентскую роль.
5. Для нескольких внутренних статусов выберите клиентские alias-статусы.
6. Войдите пользователем с выбранной ролью.
7. Откройте список задач и карточку задачи.
8. Убедитесь, что клиент видит alias-статусы, а администратор видит исходные статусы.
